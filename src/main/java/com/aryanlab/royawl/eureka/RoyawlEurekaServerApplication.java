package com.aryanlab.royawl.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;
import org.springframework.context.annotation.PropertySource;

@EnableEurekaServer
@SpringBootApplication
@PropertySource({"classpath:application-${spring.profiles.active}.properties"})
public class RoyawlEurekaServerApplication {

  public static void main(String[] args) {
    SpringApplication.run(RoyawlEurekaServerApplication.class, args);
  }

}
