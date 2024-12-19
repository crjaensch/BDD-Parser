Feature: Product Creation with Common Quote Counter

  Scenario: Designer creates product with common quote counter successfully
    Given a user with role 'Designer' in the tenant
    When the user creates a product 'P1' that uses a common quote counter
    Then the product 'P1' gets created
    And the common quote counter is initialized to zero

  Scenario: Designer cannot create product without proper role
    Given a user with role 'Agent' in the tenant
    When the user tries to create a product 'P1' that uses a common quote counter
    Then the user is not allowed to create the product