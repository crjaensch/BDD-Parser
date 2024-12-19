Feature: Login functionality

  Scenario: Successful login
    Given the user is on the login page
    When the user enters valid credentials
    Then the user is logged in

  Scenario: Unsuccessful login
    Given the user is on the login page
    When the user enters invalid credentials
    Then the user sees an error message

