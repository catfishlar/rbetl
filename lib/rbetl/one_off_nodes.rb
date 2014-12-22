require 'rbetl/etl_node'
require 'json'
require 'methadone'

module Rbetl
  class JsonTable < EtlNode
    include Methadone::CLILogging

    def publish
      pub = {}
      until (table = get).nil?
        pub = pub.merge(table)
      end
      puts JSON.pretty_generate(pub)
    end

    def process(lines)
      pub = {}
      if lines.respond_to? :each
        re = /CREATE TABLE \"(\w+)/
        match = re.match(lines[0])
        if match.nil?
          error("Class Rbetl::JsonTable is looking for a first line with CREATE_TABLE")
        else
          key = match[1]
          value = []
          lines.each do |line|
            value << line
          end
          pub[key] = value
        end
      else
        error("Class JsonTable is looking for groups of lines that make up one table")
      end
      return pub
    end


  end
  # Class LongFormTable Status
  # processes these nodes that come from:

  # mysql> show table status \G;

  # it produces the following per table.
=begin
[]'*************************** 1. row ***************************',
'           Name: AB_Split_Groups_Table',
'         Engine: InnoDB',
'        Version: 10',
'     Row_format: Compact',
'           Rows: 156',
' Avg_row_length: 105',
'    Data_length: 16384',
'Max_data_length: 0',
'   Index_length: 16384',
'      Data_free: 0',
' Auto_increment: NULL',
'    Create_time: 2014-07-17 18:30:07',
'    Update_time: NULL',
'     Check_time: NULL',
'      Collation: latin1_swedish_ci',
'       Checksum: NULL',
' Create_options: ',
'        Comment: ']

the resulting hash will all be downcased and symbolized
=end
  class LongFormTableStatus < EtlNode
    include Methadone::CLILogging
    def publish
      pub = []
      until (table = get).nil?
        pub << table
      end
      JSON.pretty_generate(pub)
    end

    def process(lines)
      pub = {}
      if lines.respond_to? :each
        if lines.shift =~ /^\*\*\*/
          lines.each do |line|
            key_val = line.split(':').map(&:strip)
            pub[key_val[0].downcase.to_sym] = (key_val[1]=='NULL' ? nil : key_val[1])
          end
        else
          error('First line is not a bunch o asterixs')
        end
      end
      pub
    end

  end

  # Table Schema

  # mysqldump -h 10.0.249.151 -u lmurdock -p --no-data --single-transaction uptilt_db > uptilt_db-schema.sql

  #it produces the following per table:
=begin
 [
%q[CREATE TABLE `Mailing_List_Deferred_Table` (],
%q[  `UNIQUE_ID` varchar(10) DEFAULT NULL,],
%q[  `MAILING_LIST_ID` int(10) unsigned DEFAULT NULL,],
%q[  `MESSAGE_ID` int(10) unsigned DEFAULT NULL,],
%q[  `RESEND_DATE` date DEFAULT NULL,],
%q[  `RESEND_ID` int(10) unsigned NOT NULL AUTO_INCREMENT,],
%q[  `SENT` enum('y','n') DEFAULT 'n',],
%q[  PRIMARY KEY (`RESEND_ID`),],
%q[  UNIQUE KEY `uidx_uidmlidmid` (`UNIQUE_ID`,`MAILING_LIST_ID`,`MESSAGE_ID`),],
%q[  KEY `idx_datesmid` (`RESEND_DATE`,`SENT`,`MESSAGE_ID`)],
%q[) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPRESSED;]
]

This is going to be converted to something like.
{
  "table_name" : "Mailing_List_Deferred_Table",
  "first_src_line" : "CREATE TABLE `Mailing_List_Deferred_Table` ("
  "last_src_line" : ") ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPRESSED;"
  "fields" : [
    {
      "field_name" : "UNIQUE_ID",
      "field_type" : "varchar",
      "field_param" : "10",
      "is_nullable" : true,
      "default_value" : "NULL",
      "src_line" : "  `UNIQUE_ID` varchar(10) DEFAULT NULL,"
    },
    { ...
    }
  ],
  "keys" : [
    {
      "key_name" : "PRIMARY"
      "is_primary" : true
      "is_unique" : false
      "key_fields" : [
        {
          "key_field_name" : "RESEND_ID",
          "key_field_order" : 1,
        }
      ]
      "src_line" : "  PRIMARY KEY (`RESEND_ID`),"
    },
    {  ....
    }
  ],

}
=end
  class TableSchema < EtlNode
    include Methadone::CLILogging
    def publish
      pub = []
      until (table = get).nil?
        pub  << table
      end
      JSON.pretty_generate(pub)
    end
    def process(lines)

      pub = {}

      if lines.respond_to? :each
        idx = 0
        sz = lines.length
        #------------- Table Name
        # line[0] should be that line.
        # ex: CREATE TABLE `Mailing_List_Deferred_Table` (
        re = /^CREATE TABLE `(.*)`/
        m = re.match(lines[idx])
        if m
          pub[:table_name] = m[1]
          pub[:first_src_line] = lines[idx]
        else
          error("First line of the table should start with CREATE TABLE")
          error("|#{lines[idx]}|")
        end
        #------------- Fields
        #lines that start with ` are fields
        # ex:    `MAILING_LIST_ID` int(10) unsigned DEFAULT NULL,
        re = /^  `([^`]*)`\s(\w+)(\((\w+)\)|)/ # 1 = field name, 2 = field_type, 4 = size
        idx = 1
        pub[:fields] = []
        while m = re.match(lines[idx]) do # process fields
          field = {}
          field[:field_name] = m[1]
          field[:field_type] = m[2]
          field[:field_param] = m[4]
          field[:is_nullable] = (lines[idx] =~ /NOT NULL/ ? false : true)
          match_default=/DEFAULT\s+'(.*)'/.match(lines[idx])
          field[:default_value] = (match_default ? match_default[1] : nil)
          field[:src_line] = lines[idx]

          pub[:fields] << field
          idx += 1
        end # fields
        #------------- Keys
        # lines that have KEY
        # ex:  PRIMARY KEY (`RESEND_ID`),
        # ex:  UNIQUE KEY `uidx_uidmlidmid` (`UNIQUE_ID`,`MAILING_LIST_ID`,`MESSAGE_ID`),
        # ex:  KEY `idx_datesmid` (`RESEND_DATE`,`SENT`,`MESSAGE_ID`)
        pub[:keys] = []
        while /^\s+\w*\s*KEY/.match(lines[idx]) do
          key = {}
          primary = (lines[idx] =~ /^\s+PRIMARY/ ? true : false)
          unique = (lines[idx] =~ /^\s+UNIQUE/ ? true : false)
          name = ''
          key_list = ''
          if primary
            m = /\((.*)\)/.match(lines[idx])
            name = 'PRIMARY'
            key_list = m[1]

          else
            m = /`(\S*)`\s+\((.*)\)/.match(lines[idx])
            name = m[1]
            key_list = m[2]

          end
          key[:key_name] = name
          key[:is_primary] = primary
          key[:is_unique] = unique
          key[:key_fields] = []
          key_list = key_list.scan(/[^`,]+/) # assumes that the list is ` and , seperated fields with no white space
          for i in 0..key_list.size - 1 do
            key[:key_fields] << {key_field_name: key_list[i], key_field_order: i }
          end
          key[:src_line] = lines[idx]

          pub[:keys] << key
          idx += 1
        end
        #-----------  Last Line
        #
        if /^\)/ =~ lines[idx]
          pub[:last_src_line] = lines[idx]
        else
          logger.error = "Something other than an end of table was found after a line inside a table that was not a field or a key.  Line is:"
          logger.error = "|#{line}|"
        end
      else
        error("class TableSchema assumes that #process is handed a array of strings with a mysql table definition")
      end
      pub
    end # process
  end
end
