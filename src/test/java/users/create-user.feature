Feature: Crear usuario (reutilizable)

  Scenario:
    * def dataGen = call read('helpers/data-generator.js')
    * def userPayload =
      """
      {
        "nome": "Usuario Karate Test",
        "email": "#(dataGen.email)",
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