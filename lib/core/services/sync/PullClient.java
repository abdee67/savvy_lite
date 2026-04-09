import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class PullClient {

    public static void main(String[] args) {
        try {

            String username = "admin";
            String sourceAddress = "branch1";

            String url = "https://yourdomain.com/api/pull"
                    + "?userName=" + username
                    + "&sourceAddress=" + sourceAddress;

            HttpClient client = HttpClient.newHttpClient();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .header("Accept", "application/json")
                    .build();

            HttpResponse<String> response = client.send(
                    request,
                    HttpResponse.BodyHandlers.ofString()
            );

            if (response.statusCode() == 200) {
                String body = response.body();

                System.out.println("Response: " + body);

              

            } else {
                System.out.println("Error: " + response.statusCode());
                System.out.println(response.body());
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}