Feature: Crear usuario (reutilizable)

  Scenario:
    * def DataGenerator = Java.type('users.helpers.DataGenerator')
    * def generatedEmail = DataGenerator.generateUniqueEmail()
    * def userPayload = read('data/new-user.json')

    Given url baseUrl
    And path 'usuarios'
    And request userPayload
    When method post
    Then status 201
    * def createdUserId = response._id
    * def createdUserEmail = userPayload.email