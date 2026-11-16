package kz.quickbites.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;
import kz.quickbites.user.UserRole;

public final class AuthDtos {
    private AuthDtos() {}
    public record RegisterRequest(@NotBlank @Size(min = 2, max = 80) String username,
                                  @NotBlank @Email @Size(max = 254) String email,
                                  @NotBlank @Size(min = 10, max = 72) String password) {}
    public record LoginRequest(@NotBlank @Email String email, @NotBlank String password) {}
    public record UserResponse(UUID id, String username, String email, UserRole role) {}
    public record AuthResponse(String tokenType, String accessToken, Instant expiresAt, UserResponse user) {}
}
