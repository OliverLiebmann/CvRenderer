import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import tech.talentbase.cv.CV;
import tech.talentbase.cv.data.Talent;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Base64;


public class CvRenderer implements RequestStreamHandler {
    @Override
    public void handleRequest(InputStream inputStream, OutputStream outputStream, Context context) throws IOException {
        LambdaLogger logger = context.getLogger();
        logger.log("Loading Java Lambda handler of ProxyWithStream");

        String request = new String(inputStream.readAllBytes());
        System.out.println(request);
        logger.log("Request: " + request);
        try {
            ByteArrayOutputStream os = new ByteArrayOutputStream();
            new CV(new Talent(), false, false).save(os);
            String encodedString = Base64.getEncoder().encodeToString(os.toByteArray());
            outputStream.write(("{\"statusCode\": 200, \"body\": \""+encodedString+"\",\"headers\": { \"Content-type\": \"application/pdf\" }}").getBytes());
            logger.log("Created CV for " + new Talent().email);
        } catch (Exception e) {
            logger.log("Exception: " + e.getMessage());

        }
    }
}
