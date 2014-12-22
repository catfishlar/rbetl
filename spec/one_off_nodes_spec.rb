require 'rspec'
require 'rbetl'

describe 'Json table' do

  it 'should Convert table to hash' do
    table_lines = double('table_lines', get: [
                                          'CREATE TABLE "Automator_Log_Logger"  (',
                                          '	"AUTOMATOR_LOG_LOGGER_ID"	int(10) UNSIGNED NOT NULL DEFAULT \'0\',',
                                          '	"LOGGER_NAME"            	varchar(50) NOT NULL,',
                                          '	PRIMARY KEY("AUTOMATOR_LOG_LOGGER_ID")',
                                          ')',
                                          'ENGINE = InnoDB',
                                          'AUTO_INCREMENT = 0',
                                          'ROW_FORMAT = COMPRESSED',
                                          'GO'
                                      ])
    jsont = Rbetl::JsonTable.new(table_lines)
    val = jsont.get
    val.class.should == Hash
    val.size.should == 1
    val['Automator_Log_Logger'].size.should == 9
  end
end

# Class LongFormTable Status
# processes these nodes that come from:

# mysql> show table status \G;

# it produces the following per table.
describe 'Table Status Long Form' do

  before(:each) do
    table_text = double('long form table text')
    allow(table_text).to receive(:get).and_return( [
'*************************** 1. row ***************************',
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
'        Comment: '], nil)
    @tstatus = Rbetl::LongFormTableStatus.new(table_text)
  end

  it 'should Convert Status to hash' do

    thash = @tstatus.get
    thash.class.should == Hash
    thash.size.should == 18
  end

  it 'should turn NULL into nil' do
    thash = @tstatus.get
    thash.each do |key, value|
      value.should_not == 'NULL'
    end
  end

  it 'field names should be downcased and symbolized' do
    pending('check if :name is a key')
  end
  it 'should turn publish as JSON' do
    tarray = JSON.parse(@tstatus.publish)
    expect(tarray.length).to eq(1)
    tarray[0].size.should == 18
  end
end

# Table Schema
# mysqldump -h 10.0.249.151 -u lmurdock -p --no-data --single-transaction uptilt_db > uptilt_db-schema.sql
#it produces the following per table:

describe 'Table Schema' do

  before(:each) do
    table_text = double('Table Schema')
    allow(table_text).to receive(:get).and_return( [
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
],nil)
    @tstatus = Rbetl::TableSchema.new(table_text)
  end

  it 'should Convert Schema to a hash' do

    thash = @tstatus.get
    thash.class.should == Hash
    thash.size.should == 5
    expect(thash).to have_key(:table_name)
    expect(thash).to have_key(:first_src_line)
    expect(thash).to have_key(:fields)
    expect(thash).to have_key(:keys)
    expect(thash).to have_key(:last_src_line)
  end

  it 'should Preserve fields in a src_line element' do

    thash = @tstatus.get
    expect(thash[:fields].length).to equal(6)
    thash[:fields].each do |fld|
      expect(fld).to have_key(:src_line)
      expect(fld[:src_line]).to_not be_nil
      expect(fld[:src_line]).to_not equal('')
    end
  end
  it 'should turn publish as JSON' do
    tarray = JSON.parse(@tstatus.publish)
    expect(tarray.length).to eq(1)
  end
end
