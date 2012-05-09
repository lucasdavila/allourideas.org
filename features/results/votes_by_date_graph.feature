Feature: Objects over time graphs 
  In order to view the popularity of an idea marketplace
  A user
  Should be able to view a graph displaying the number of votes over time

  @selenium
  Scenario: No votes, so no chart possible
     Given an idea marketplace quickly exists with url 'test'
     And I am on the View Results page for 'test'
     When I follow "votes-datechart-view-link"
     Then I should see "Number of Votes per day Overall total - 0" within ".highcharts-container"
  
  @selenium
  Scenario: Some votes on one day
     Given an idea marketplace quickly exists with url 'test'
     And I am on the Cast Votes page for 'test'
     When I vote 3 times
     And I go to the View Results page for 'test'
     And I follow "votes-datechart-view-link"
     Then I should see "Number of Votes per day Overall total - 3" within ".highcharts-container"
    
