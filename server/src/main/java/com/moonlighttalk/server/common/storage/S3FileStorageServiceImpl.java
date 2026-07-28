package com.moonlighttalk.server.common.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;

@Service
@ConditionalOnProperty(name = "app.storage.type", havingValue = "s3")
public class S3FileStorageServiceImpl implements FileStorageService {

    private static final Duration UPLOAD_URL_TTL = Duration.ofMinutes(10);

    private final S3Presigner presigner;
    private final S3Client s3Client;
    private final String bucket;
    private final Duration downloadUrlTtl;

    public S3FileStorageServiceImpl(
            S3Presigner presigner,
            S3Client s3Client,
            @Value("${app.storage.bucket}") String bucket,
            @Value("${app.storage.download-url-ttl-minutes:10}") long downloadUrlTtlMinutes
    ) {
        this.presigner = presigner;
        this.s3Client = s3Client;
        this.bucket = bucket;
        this.downloadUrlTtl = Duration.ofMinutes(downloadUrlTtlMinutes);
    }

    @Override
    public String issueUploadUrl(String key, String contentType) {
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(contentType)
                .build();
        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(UPLOAD_URL_TTL)
                .putObjectRequest(putRequest)
                .build();
        return presigner.presignPutObject(presignRequest).url().toString();
    }

    @Override
    public String issueDownloadUrl(String key) {
        GetObjectRequest getRequest = GetObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build();
        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(downloadUrlTtl)
                .getObjectRequest(getRequest)
                .build();
        return presigner.presignGetObject(presignRequest).url().toString();
    }

    @Override
    public void delete(String key) {
        s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
    }
}
