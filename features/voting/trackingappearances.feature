Feature: Tracking appearances
  In order to determine when users leave our site without voting
  A user
  Should have the prompts that they view recorded as appearances
   
    Background: 
	Given an idea marketplace quickly exists with url 'test'
	And I am on the Cast Votes page for 'test'
        And I save the current appearance lookup
 
       @selenium
       Scenario: User gets a new appearance after submitting a cant decide
	  When I click the I can't decide button
	  And I pick "I like both ideas"
	  And I click the I can't decide button
    Then the current appearance lookup should not match the saved appearance lookup

       @selenium
       Scenario: User gets a new appearance after submitting a vote
          When I click on the left choice 
          Then I should see "You chose" within ".tellmearea"
          And the current appearance lookup should not match the saved appearance lookup
       
       Scenario: User reloads the page
          When I go to the Cast Votes page for 'test'
          Then the current appearance lookup should match the saved appearance lookup
