package com.moonlighttalk.server.common.storage;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * 로컬 스토리지 모드 전용 업로드/다운로드 엔드포인트(05 문서 §8).
 * 일반 @RestController라서 JwtAuthInterceptor가 정상 적용 — 두 엔드포인트 모두 인증 필요.
 * key에 슬래시가 포함되므로 경로 변수가 아닌 쿼리 파라미터로 받는다.
 */
@RestController
@ConditionalOnProperty(name = "app.storage.type", havingValue = "local", matchIfMissing = true)
public class FileTransferController {

    private final LocalFileStorageServiceImpl localStorage;

    public FileTransferController(LocalFileStorageServiceImpl localStorage) {
        this.localStorage = localStorage;
    }

    @PutMapping("/internal/files")
    public ResponseEntity<Void> upload(@RequestParam String key, HttpServletRequest request) throws IOException {
        try (var input = request.getInputStream()) {
            localStorage.store(key, input);
        }
        return ResponseEntity.ok().build();
    }

    @GetMapping("/files")
    public ResponseEntity<Resource> download(@RequestParam String key) throws IOException {
        Path path = localStorage.resolve(key);
        if (!Files.exists(path)) {
            return ResponseEntity.notFound().build();
        }
        String contentType = Files.probeContentType(path);
        return ResponseEntity.ok()
                .contentType(contentType != null ? MediaType.parseMediaType(contentType) : MediaType.APPLICATION_OCTET_STREAM)
                .body(new FileSystemResource(path));
    }
}
