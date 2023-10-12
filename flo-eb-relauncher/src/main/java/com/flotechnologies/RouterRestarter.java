package com.flotechnologies;

import com.amazonaws.services.elasticbeanstalk.AWSElasticBeanstalk;
import com.amazonaws.services.elasticbeanstalk.AWSElasticBeanstalkClientBuilder;
import com.amazonaws.services.elasticbeanstalk.model.RestartAppServerRequest;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;


public class RouterRestarter implements RequestHandler<ScheduledEvent, String> {
    private final String ENVIRONMENT_ID_VARIABLE = "EB_ENVIRONMENT_ID";

    @Override
    public String handleRequest(ScheduledEvent event, Context context) {
        String envId = System.getenv(ENVIRONMENT_ID_VARIABLE);

        AWSElasticBeanstalk eb = AWSElasticBeanstalkClientBuilder.standard().withRegion("us-west-2").build();
        RestartAppServerRequest restartAppServerRequest = new RestartAppServerRequest();
        if (envId != null) {
            restartAppServerRequest.setEnvironmentId(envId);
            eb.restartAppServer(restartAppServerRequest);
            return "OK";
        } else {
            return "FAIL";
        }

    }
}
