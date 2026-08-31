package users.helpers;

public class DataGenerator {

    public static String generateUniqueEmail() {
        long timestamp = System.currentTimeMillis();
        return "karate.test." + timestamp + "@qa.com";
    }
}