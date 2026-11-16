package kz.quickbites.security;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Arrays;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import com.nimbusds.jose.jwk.source.ImmutableSecret;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import kz.quickbites.user.UserRepository;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    SecretKey jwtSecretKey(@Value("${app.auth.jwt-secret}") String secret) {
        byte[] bytes = secret.getBytes(StandardCharsets.UTF_8);
        if (secret.isBlank() || bytes.length < 32)
            throw new IllegalStateException("JWT_SECRET must contain at least 32 bytes");
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey key) { return new NimbusJwtEncoder(new ImmutableSecret<>(key)); }

    @Bean
    JwtDecoder jwtDecoder(SecretKey key) {
        return NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter(UserRepository users) {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            String subject = jwt.getSubject();
            return users.findByEmailIgnoreCase(subject)
                    .filter(user -> user.isActive())
                    .<GrantedAuthority>map(user -> new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
                    .map(List::of)
                    .orElseGet(List::of);
        });
        return converter;
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthenticationConverter jwtConverter) throws Exception {
        http.csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/actuator/health/**", "/api/auth/**").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("CAMPUS_ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/buffets", "/api/buffets/*/menu", "/api/buffets/*/pickup-slots").permitAll()
                        .anyRequest().hasAnyRole("STUDENT", "BUFFET_STAFF", "CAMPUS_ADMIN"))
                .oauth2ResourceServer(oauth -> oauth.jwt(jwt -> jwt.jwtAuthenticationConverter(jwtConverter)));
        return http.build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(@Value("${app.cors.allowed-origins}") String allowedOrigins) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.stream(allowedOrigins.split(","))
                .map(String::trim).filter(origin -> !origin.isBlank()).toList());
        config.setAllowedMethods(List.of("GET", "POST", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setExposedHeaders(List.of("Location"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
