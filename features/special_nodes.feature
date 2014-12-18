Feature: Additional single purpose nodes
  As a user of rbetl
  I will have special one off processing needs that I will want to keep in a seperate place
  So that I can keep everything straight

  Scenario: JSONTABLE Special output should create a hash with dbtablename as key and array of lines as value
    Given a file named "table" with:
    """
CREATE TABLE "Automator_Log_Logger"  (
	"AUTOMATOR_LOG_LOGGER_ID"	int(10) UNSIGNED NOT NULL DEFAULT '0',
	"LOGGER_NAME"            	varchar(50) NOT NULL,
	PRIMARY KEY("AUTOMATOR_LOG_LOGGER_ID")
)
ENGINE = InnoDB
AUTO_INCREMENT = 0
ROW_FORMAT = COMPRESSED
GO
    """
    When I run `rbetl --input=table --regex --process="BETWEEN/^CREATE/^GO" --output="JSONTABLE"`
    Then  the output should contain "{"
    And the output should contain "Automator_Log_Logger"
