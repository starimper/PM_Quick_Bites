package kz.quickbites.admin;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class AdminDtos {
    private AdminDtos() {}
    public record CreateStaffRequest(@NotBlank @Size(min = 2, max = 80) String username,
                                     @NotBlank @Email String email,
                                     @NotBlank @Size(min = 10, max = 72) String temporaryPassword) {}
    public record StaffResponse(UUID id, String username, String email, String role) {}
    public record ActiveRequest(boolean active) {}
    public record UserStatusResponse(UUID id, String username, String email, String role, boolean active) {}
}
