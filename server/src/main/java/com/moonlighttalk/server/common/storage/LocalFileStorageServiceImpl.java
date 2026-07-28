package com.moonlighttalk.server.common.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

@Service
@ConditionalOnProperty(name = "app.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalFileStorageServiceImpl implements FileStorageService {

    private final Path root;

    public LocalFileStorageServiceImpl(@Value("${app.storage.local-path:server/uploads}") String localPath) {
        this.root = Path.of(localPath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new IllegalStateException("로컬 스토리지 경로를 생성할 수 없습니다: " + root, e);
        }
    }

    @Override
    public String issueUploadUrl(String key, String contentType) {
        return UriComponentsBuilder.fromPath("/internal/files")
                .queryParam("key", key)
                .build()
                .toUriString();
    }

    @Override
    public String issueDownloadUrl(String key) {
        return UriComponentsBuilder.fromPath("/files")
                .queryParam("key", key)
                .build()
                .toUriString();
    }

    @Override
    public void delete(String key) {
        try {
            Files.deleteIfExists(resolve(key));
        } catch (IOException e) {
            throw new IllegalStateException("파일 삭제 실패: " + key, e);
        }
    }

    public void store(String key, InputStream data) {
        Path target = resolve(key);
        try {
            Files.createDirectories(target.getParent());
            Files.copy(data, target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new IllegalStateException("파일 저장 실패: " + key, e);
        }
    }

    /** key의 경로 이탈(../)을 막기 위해 root 하위인지 검증 후 절대경로로 변환. */
    public Path resolve(String key) {
        Path target = root.resolve(key).normalize();
        if (!target.startsWith(root)) {
            throw new IllegalArgumentException("잘못된 파일 key 입니다: " + key);
        }
        return target;
    }
}
