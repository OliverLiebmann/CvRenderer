import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import tech.talentbase.cv.CV;
import tech.talentbase.cv.data.Talent;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.http.HttpHeaders;
import java.time.Duration;
import java.util.*;

public class DownloadFileHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent input, Context context) {
        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();

        try {

            // Assuming you can deserialize the JSON body into a Talent object
            //      Talent talent = YourJsonDeserializer.deserialize(input.getBody());

            ByteArrayOutputStream os = new ByteArrayOutputStream();

            Talent talent = new Talent();
            talent.firstName = "John";
            talent.lastName = "Doe";
            talent.email = "test@email.com";
            new CV(talent, false, false).save(os);


            byte[] contents = os.toByteArray();

            Map<String, String> headers = new HashMap<>();
            headers.put("Content-type", "application/pdf");
            String filename = "CV.pdf";

            headers.put("Content-Disposition", "attachment; filename=\"" + filename + "\"");
            headers.put("Cache-Control", "must-revalidate, post-check=0, pre-check=0");

            // Create APIGatewayProxyResponseEvent
            response.setStatusCode(200);
            response.setHeaders(headers);
            response.setBody(new String(contents));
        } catch (IOException e) {
            response.setBody("Error generating CV");
        }

        return response;
    }
}
