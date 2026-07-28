package com.moonlighttalk.server.auth.service;

import com.moonlighttalk.server.auth.dto.AuthResponse;
import com.moonlighttalk.server.auth.dto.TokenPairResponse;
import com.moonlighttalk.server.auth.dto.UserSummary;
import com.moonlighttalk.server.auth.entity.User;
import com.moonlighttalk.server.auth.mapper.UserMapper;
import com.moonlighttalk.server.auth.social.SocialAuthProvider;
import com.moonlighttalk.server.auth.social.SocialAuthProviderRegistry;
import com.moonlighttalk.server.auth.social.SocialProvider;
import com.moonlighttalk.server.auth.social.SocialUserInfo;
import com.moonlighttalk.server.common.exception.ApiException;
import com.moonlighttalk.server.common.exception.UnauthorizedException;
import com.moonlighttalk.server.common.response.ErrorCode;
import com.moonlighttalk.server.common.security.JwtProvider;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserMapper userMapper;
    private final SocialAuthProviderRegistry socialAuthProviderRegistry;
    private final JwtProvider jwtProvider;

    public AuthService(UserMapper userMapper,
                        SocialAuthProviderRegistry socialAuthProviderRegistry,
                        JwtProvider jwtProvider) {
        this.userMapper = userMapper;
        this.socialAuthProviderRegistry = socialAuthProviderRegistry;
        this.jwtProvider = jwtProvider;
    }

    @Transactional
    public AuthResponse socialLogin(SocialProvider provider, String providerToken) {
        SocialAuthProvider authProvider = socialAuthProviderRegistry.find(provider)
                .orElseThrow(() -> new ApiException(ErrorCode.PROVIDER_DISABLED, HttpStatus.CONFLICT,
                        provider + " 로그인은 현재 비활성화되어 있습니다."));

        SocialUserInfo socialUserInfo = authProvider.verify(providerToken);

        User user = userMapper.findByProvider(provider.name(), socialUserInfo.providerUid());
        boolean isNew = (user == null);
        if (isNew) {
            user = new User();
            user.setId(UUID.randomUUID().toString());
            user.setProvider(provider.name());
            user.setProviderUid(socialUserInfo.providerUid());
            user.setStatus("ACTIVE");
            user.setPremium(false);
            userMapper.insert(user);
        }

        if (user.isBanned()) {
            return new AuthResponse("BANNED", null, null, new UserSummary(user.getId(), user.getNickname()));
        }

        String status = isNew ? "NEW" : (user.isProfileComplete() ? "ACTIVE" : "PROFILE_REQUIRED");
        String accessToken = jwtProvider.issueAccessToken(user.getId());
        String refreshToken = jwtProvider.issueRefreshToken(user.getId());
        return new AuthResponse(status, accessToken, refreshToken, new UserSummary(user.getId(), user.getNickname()));
    }

    public TokenPairResponse refresh(String refreshToken) {
        String userId;
        try {
            if (!jwtProvider.isRefreshToken(refreshToken)) {
                throw new UnauthorizedException("refreshToken이 아닙니다.");
            }
            userId = jwtProvider.parseUserId(refreshToken);
        } catch (UnauthorizedException e) {
            throw e;
        } catch (RuntimeException e) {
            throw new UnauthorizedException("유효하지 않은 refreshToken 입니다.");
        }

        User user = userMapper.findById(userId);
        if (user == null || user.isBanned()) {
            throw new UnauthorizedException("사용할 수 없는 계정입니다.");
        }

        return new TokenPairResponse(
                jwtProvider.issueAccessToken(userId),
                jwtProvider.issueRefreshToken(userId)
        );
    }
}
