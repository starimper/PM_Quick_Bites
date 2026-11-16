package kz.quickbites.admin;

import jakarta.validation.Valid;
import kz.quickbites.buffet.BuffetDtos;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
    private final AdminService admin;
    public AdminController(AdminService admin) { this.admin = admin; }
    @PostMapping("/staff") @ResponseStatus(HttpStatus.CREATED)
    public AdminDtos.StaffResponse createStaff(@Valid @RequestBody AdminDtos.CreateStaffRequest request) { return admin.createStaff(request); }
    @PostMapping("/buffets") @ResponseStatus(HttpStatus.CREATED)
    public BuffetDtos.BuffetResponse createBuffet(@Valid @RequestBody BuffetDtos.CreateBuffetRequest request) { return admin.createBuffet(request); }
    @PatchMapping("/users/{userId}/active")
    public AdminDtos.UserStatusResponse setActive(@PathVariable UUID userId, @Valid @RequestBody AdminDtos.ActiveRequest request,
                                                  @AuthenticationPrincipal Jwt jwt) {
        return admin.setActive(userId, request.active(), jwt.getSubject());
    }
}
