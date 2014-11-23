Feature: Complex line processing
  In order to process schema files
  I want a one-command way to pull out context
    dependent lines from a file
  and do a variety of processing on those lines
  So that I can grow a set of processing abilities in
    my tool set

  Scenario: Basic UI
    When I get help for "rbetl"
    Then the exit status should be 0
    And the banner should be present
    And the banner should include the version
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
      |--input  |
      |--regex  |
      |--process|
      |--combine|
      |--output |
    And the banner should document that this app takes no arguments

  Scenario: file to StdOut Passthrough - basically unix cat
    Given a file named "bob" with:
    """
    first
    second
    last
    """
    When I run `rbetl --input=bob`
    Then the output should contain:
    """
    first
    second
    last
    """

  Scenario: Output all lines from the file with a literal pattern
    Given a file named "bob" with:
    """
    mlly
    m?lly
    justin
    """
    When I run `rbetl --input=bob --process="PATTERN/m?lly/0"`
    Then  the output should contain "m?lly"
    And the output should not contain "mlly"
    And the output should not contain "justin"


  Scenario: Output all lines from the file with a regex pattern
    Given a file named "bob" with:
    """
    molly
    mlly
    justin
    """
    When I run `rbetl --input=bob --regex --process="PATTERN/mo?lly/0"`
    Then  the output should contain "molly"
    And the output should contain "mlly"
    And the output should not contain "justin"

  Scenario: Output all lines from the file with a regex pattern and the context
    Given a file named "bob" with:
    """
    molly
    mlly    the code has to reset the context (the number of lines after the match) bc of a second match
    justin
    jim
    """
    When I run `rbetl --input=bob --regex --process="PATTERN/mo?lly/1"`
    Then  the output should contain "molly"
    And the output should contain "mlly"
    And the output should contain "justin"    
    And the output should not contain "jim"

  Scenario: Output lines between two patterns
    Given a file named "bob" with:
    """
    jesse
    begin
    molly
    end
    justin
    """
    When I run `rbetl --input=bob --process="BETWEEN/begin/end"`
    Then  the output should contain:
  """
  begin
  molly
  end
  """
    And the output should not contain "jesse"
    And the output should not contain "justin"

  Scenario: Output lines between two patterns as a single line
    Given a file named "bob" with:
    """
    jesse
    begin
    molly
    end
    justin
    """
    When I run `rbetl --input=bob --process="BETWEEN/begin/end" --combine="|"`
    Then  the output should contain "begin|molly|end"
    And the output should not contain "jesse"
    And the output should not contain "justin"