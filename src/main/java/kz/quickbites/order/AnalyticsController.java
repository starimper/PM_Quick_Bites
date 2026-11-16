
package kz.quickbites.order;

import java.security.Principal;
import java.util.UUID;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/buffets/{buffetId}/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(
            AnalyticsService analyticsService
    ) {
        this.analyticsService = analyticsService;
    }

    @GetMapping
    public AnalyticsService.AnalyticsResponse getAnalytics(
            @PathVariable UUID buffetId,
            @RequestParam(defaultValue = "7") int days,
            Principal principal
    ) {
        return analyticsService.getAnalytics(
                buffetId,
                principal.getName(),
                days
        );
    }
}
