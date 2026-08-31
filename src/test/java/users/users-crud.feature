Feature: CRUD de usuarios - ServeRest

  Background:
    * url baseUrl

  Scenario: CT-01 - Listar usuarios registrados
    Given path 'usuarios'
    When method get
    Then status 200
    And match response.usuarios == '#array'
    And match response.quantidade == '#number'

  Scenario Outline: CT-03 - No permite registrar usuario sin el campo <campo>
    * def payload = { nome: 'Usuario Test', email: 'test.<campo>@qa.com', password: 'teste123', administrador: 'true' }
    * remove payload.<campo>
    * def expected = {}
    * eval expected[campo] = mensaje
    Given path 'usuarios'
    And request payload
    When method post
    Then status 400
    And match response == expected

    Examples:
      | campo         | mensaje                        |
      | nome          | nome é obrigatório              |
      | email         | email é obrigatório             |
      | password      | password é obrigatório          |
      | administrador | administrador é obrigatório     |

  Scenario: CT-07 - Buscar usuario con ID inexistente
    Given path 'usuarios', 'abcd1234abcd1234'
    When method get
    Then status 400
    And match response == { message: 'Usuário não encontrado' }

  Scenario: CT-12 - Eliminar usuario con ID inexistente no genera error
    Given path 'usuarios', 'abcd1234abcd1234'
    When method delete
    Then status 200
    And match response == { message: 'Nenhum registro excluído' }

  Scenario: CT-05 - No permite registrar usuario con email ya utilizado
    * def created = call read('create-user.feature')
    * def payload = { nome: 'Otro Usuario', email: '#(created.createdUserEmail)', password: 'teste123', administrador: 'false' }
    Given path 'usuarios'
    And request payload
    When method post
    Then status 400
    And match response == { message: 'Este email já está sendo usado' }

  Scenario: CT-06 - Buscar usuario existente por ID
    * def created = call read('create-user.feature')
    * def schema = read('schemas/user-schema.js')
    Given path 'usuarios', created.createdUserId
    When method get
    Then status 200
    And match response == schema
    And match response.email == created.createdUserEmail

  Scenario: CT-08 - Actualizar usuario y confirmar el cambio real
    * def created = call read('create-user.feature')
    * def dataGen = call read('helpers/data-generator.js')
    * def updatedPayload = { nome: 'Usuario Actualizado', email: '#(dataGen.email)', password: 'nuevaClave123', administrador: 'false' }
    Given path 'usuarios', created.createdUserId
    And request updatedPayload
    When method put
    Then status 200
    And match response == { message: 'Registro alterado com sucesso' }

    Given path 'usuarios', created.createdUserId
    When method get
    Then status 200
    And match response.nome == updatedPayload.nome
    And match response.email == updatedPayload.email

  Scenario: CT-09 - Actualizar con ID inexistente crea un usuario nuevo
    * def dataGen = call read('helpers/data-generator.js')
    * def payload = { nome: 'Usuario Via PUT', email: '#(dataGen.email)', password: 'teste123', administrador: 'false' }
    * def fakeId = 'abcd1234abcd1234'
    Given path 'usuarios', fakeId
    And request payload
    When method put
    Then status 201
    And match response.message == 'Cadastro realizado com sucesso'
    And match response._id != fakeId

  Scenario: CT-10 - No permite actualizar con email ya usado por otro usuario
    * def userA = call read('create-user.feature')
    * def userB = call read('create-user.feature')
    * def payload = { nome: 'Usuario B', email: '#(userA.createdUserEmail)', password: 'teste123', administrador: 'false' }
    Given path 'usuarios', userB.createdUserId
    And request payload
    When method put
    Then status 400
    And match response == { message: 'Este email já está sendo usado' }

  Scenario: CT-11 - Eliminar usuario y confirmar que ya no existe
    * def created = call read('create-user.feature')
    Given path 'usuarios', created.createdUserId
    When method delete
    Then status 200
    And match response == { message: 'Registro excluído com sucesso' }

    Given path 'usuarios', created.createdUserId
    When method get
    Then status 400
    And match response == { message: 'Usuário não encontrado' }