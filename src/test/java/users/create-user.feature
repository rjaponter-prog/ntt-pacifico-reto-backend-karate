Feature: Crear usuario (reutilizable)

  Scenario:
    * def DataGenerator = Java.type('users.helpers.DataGenerator')
    * def generatedEmail = DataGenerator.generateUniqueEmail()
    * def userPayload =
      """
      {
        "nome": "Usuario Karate Test",
        "email": "#(generatedEmail)",
        "password": "teste123",
        "administrador": "true"
      }
      """
    Given url baseUrl
    And path 'usuarios'
    And request userPayload
    When method post
    Then status 201
    * def createdUserId = response._id
    * def createdUserEmail = userPayload.email