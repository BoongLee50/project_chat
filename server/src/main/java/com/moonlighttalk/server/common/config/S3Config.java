package com.moonlighttalk.server.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

/** app.storage.type=s3 일 때만 활성화(05 문서 §8). */
@Configuration
@ConditionalOnProperty(name = "app.storage.type", havingValue = "s3")
public class S3Config {

    @Bean
    public S3Client s3Client(@Value("${app.storage.region:ap-northeast-2}") String region) {
        return S3Client.builder().region(Region.of(region)).build();
    }

    @Bean
    public S3Presigner s3Presigner(@Value("${app.storage.region:ap-northeast-2}") String region) {
        return S3Presigner.builder().region(Region.of(region)).build();
    }
}
