package kz.quickbites.auth;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Locale;
import kz.quickbites.common.ApiException;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;
    private final long ttlMinutes;
    private final String[] allowedDomains;

    public AuthService(UserRepository users, PasswordEncoder passwordEncoder, JwtEncoder jwtEncoder,
                       @Value("${app.auth.jwt-ttl-minutes:120}") long ttlMinutes,
                       @Value("${app.auth.allowed-email-domains:kbtu.kz}") String domains) {
        this.users = users; this.passwordEncoder = passwordEncoder; this.jwtEncoder = jwtEncoder; this.ttlMinutes = ttlMinutes;
        this.allowedDomains = Arrays.stream(domains.split(",")).map(String::trim).filter(s -> !s.isBlank()).map(s -> s.toLowerCase(Locale.ROOT)).toArray(String[]::new);
    }

    @Transactional
    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        String domain = email.substring(email.lastIndexOf('@') + 1);
        if (Arrays.stream(allowedDomains).noneMatch(domain::equals))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Use your university email address");
        if (users.existsByEmailIgnoreCase(email)) throw ApiException.conflict("An account with this email already exists");
        AppUser user = users.save(new AppUser(request.username().trim(), email, passwordEncoder.encode(request.password()), UserRole.STUDENT));
        return issueToken(user);
    }

    @Transactional(readOnly = true)
    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        AppUser user = users.findByEmailIgnoreCase(request.email().trim())
                .filter(AppUser::isActive)
                .filter(candidate -> passwordEncoder.matches(request.password(), candidate.getPasswordHash()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Email or password is incorrect"));
        return issueToken(user);
    }

    private AuthDtos.AuthResponse issueToken(AppUser user) {
        Instant now = Instant.now();
        Instant expiry = now.plus(ttlMinutes, ChronoUnit.MINUTES);
        JwtClaimsSet claims = JwtClaimsSet.builder().issuer("quick-bites-api").issuedAt(now).expiresAt(expiry)
                .subject(user.getEmail()).claim("uid", user.getId().toString()).claim("role", user.getRole().name()).build();
        String token = jwtEncoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        return new AuthDtos.AuthResponse("Bearer", token, expiry,
                new AuthDtos.UserResponse(user.getId(), user.getUsername(), user.getEmail(), user.getRole()));
    }
}
