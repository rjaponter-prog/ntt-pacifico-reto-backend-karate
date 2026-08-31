function fn() {
    var timestamp = new Date().getTime();
    var email = 'karate.test.' + timestamp + '@qa.com';
    return { email: email };
}