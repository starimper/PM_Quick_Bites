package kz.quickbites.admin;

import java.util.Locale;
import java.util.UUID;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetDtos;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.common.ApiException;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminService {
    private final UserRepository users;
    private final BuffetRepository buffets;
    private final PasswordEncoder passwordEncoder;
    public AdminService(UserRepository users, BuffetRepository buffets, PasswordEncoder passwordEncoder) {
        this.users = users; this.buffets = buffets; this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public AdminDtos.StaffResponse createStaff(AdminDtos.CreateStaffRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        if (users.existsByEmailIgnoreCase(email)) throw ApiException.conflict("An account with this email already exists");
        AppUser staff = users.save(new AppUser(request.username().trim(), email,
                passwordEncoder.encode(request.temporaryPassword()), UserRole.BUFFET_STAFF));
        return new AdminDtos.StaffResponse(staff.getId(), staff.getUsername(), staff.getEmail(), staff.getRole().name());
    }

    @Transactional
    public BuffetDtos.BuffetResponse createBuffet(BuffetDtos.CreateBuffetRequest request) {
        if (request.ownerId() == null) throw ApiException.badRequest("A buffet staff owner is required");
        AppUser owner = users.findById(request.ownerId()).orElseThrow(() -> ApiException.notFound("Staff owner not found"));
        if (owner.getRole() != UserRole.BUFFET_STAFF) throw ApiException.badRequest("Buffet owner must be a buffet staff account");
        Buffet buffet = buffets.save(new Buffet(request.name().trim(), request.location().trim(), owner));
        return new BuffetDtos.BuffetResponse(buffet.getId(), buffet.getName(), buffet.getLocation(), buffet.getOwner().getId());
    }

    @Transactional
    public AdminDtos.UserStatusResponse setActive(UUID userId, boolean active, String actorEmail) {
        AppUser actor = users.findByEmailIgnoreCase(actorEmail).orElseThrow(() -> ApiException.notFound("User not found"));
        if (actor.getId().equals(userId)) throw ApiException.conflict("An administrator cannot deactivate their own account");
        AppUser user = users.findById(userId).orElseThrow(() -> ApiException.notFound("User not found"));
        user.setActive(active);
        return new AdminDtos.UserStatusResponse(user.getId(), user.getUsername(), user.getEmail(), user.getRole().name(), user.isActive());
    }
}
