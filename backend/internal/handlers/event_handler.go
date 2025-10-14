package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"
)

// EventHandler handles event-related API endpoints
type EventHandler struct {
	eventRepo *repository.EventRepository
}

// NewEventHandler creates a new event handler
func NewEventHandler(eventRepo *repository.EventRepository) *EventHandler {
	return &EventHandler{
		eventRepo: eventRepo,
	}
}

// parseDateTime parses datetime string with multiple format support
func parseDateTime(dateStr string) (time.Time, error) {
	// Try multiple date formats
	formats := []string{
		time.RFC3339,                 // "2006-01-02T15:04:05Z07:00"
		"2006-01-02T15:04:05.000Z07:00", // With milliseconds and timezone
		"2006-01-02T15:04:05.000Z",   // With milliseconds, UTC
		"2006-01-02T15:04:05.000",    // With milliseconds, no timezone
		"2006-01-02T15:04:05Z",       // UTC format
		"2006-01-02T15:04:05",        // Without timezone
		"2006-01-02 15:04:05",        // Space separator
		time.RFC3339Nano,             // With nanoseconds
	}

	var lastErr error
	for _, format := range formats {
		if t, err := time.Parse(format, dateStr); err == nil {
			return t, nil
		} else {
			lastErr = err
		}
	}

	return time.Time{}, lastErr
}

// Event endpoints

// CreateEvent creates a new event (Admin only)
func (h *EventHandler) CreateEvent(c *gin.Context) {
	var req struct {
		Name                string   `json:"name" binding:"required"`
		Type                string   `json:"type" binding:"required"`
		Date                string   `json:"date" binding:"required"`
		Description         *string  `json:"description"`
		ThemeColor          *string  `json:"themeColor"`
		IconURL             *string  `json:"iconUrl"`
		IsRecurring         bool     `json:"isRecurring"`
		SuggestedCategories []string `json:"suggestedCategories"`
		BannerTemplate      *string  `json:"bannerTemplate"`
		IsActive            bool     `json:"isActive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Parse the date string with multiple format support
	eventDate, err := parseDateTime(req.Date)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid date format: " + err.Error(),
		})
		return
	}

	event := &models.Event{
		Name:                req.Name,
		Type:                req.Type,
		Date:                eventDate,
		Description:         req.Description,
		ThemeColor:          req.ThemeColor,
		IconURL:             req.IconURL,
		IsRecurring:         req.IsRecurring,
		SuggestedCategories: req.SuggestedCategories,
		BannerTemplate:      req.BannerTemplate,
		IsActive:            req.IsActive,
	}

	if err := h.eventRepo.CreateEvent(c.Request.Context(), event); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Event created successfully",
		"data":    event,
	})
}

// GetEvents gets all events
func (h *EventHandler) GetEvents(c *gin.Context) {
	upcomingOnly := c.Query("upcomingOnly") == "true"
	activeOnly := c.Query("activeOnly") == "true"

	var events []models.Event
	var err error

	if upcomingOnly {
		events, err = h.eventRepo.GetUpcomingEvents(c.Request.Context(), 50)
	} else {
		events, err = h.eventRepo.GetAllEvents(c.Request.Context(), activeOnly)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    events,
	})
}

// GetEvent gets a single event by ID
func (h *EventHandler) GetEvent(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid event ID",
		})
		return
	}

	event, err := h.eventRepo.GetEventByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Event not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    event,
	})
}

// UpdateEvent updates an event (Admin only)
func (h *EventHandler) UpdateEvent(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid event ID",
		})
		return
	}

	var req struct {
		Name                string   `json:"name"`
		Type                string   `json:"type"`
		Date                string   `json:"date"`
		Description         *string  `json:"description"`
		ThemeColor          *string  `json:"themeColor"`
		IconURL             *string  `json:"iconUrl"`
		IsRecurring         bool     `json:"isRecurring"`
		SuggestedCategories []string `json:"suggestedCategories"`
		BannerTemplate      *string  `json:"bannerTemplate"`
		IsActive            bool     `json:"isActive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Parse the date string with multiple format support
	eventDate, err := parseDateTime(req.Date)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid date format: " + err.Error(),
		})
		return
	}

	event := &models.Event{
		ID:                  id,
		Name:                req.Name,
		Type:                req.Type,
		Date:                eventDate,
		Description:         req.Description,
		ThemeColor:          req.ThemeColor,
		IconURL:             req.IconURL,
		IsRecurring:         req.IsRecurring,
		SuggestedCategories: req.SuggestedCategories,
		BannerTemplate:      req.BannerTemplate,
		IsActive:            req.IsActive,
	}

	if err := h.eventRepo.UpdateEvent(c.Request.Context(), id, event); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Event updated successfully",
		"data":    event,
	})
}

// DeleteEvent deletes an event (Admin only)
func (h *EventHandler) DeleteEvent(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid event ID",
		})
		return
	}

	if err := h.eventRepo.DeleteEvent(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Event deleted successfully",
	})
}

// Banner endpoints

// CreateBanner creates a new banner (Admin only)
func (h *EventHandler) CreateBanner(c *gin.Context) {
	var req struct {
		Title           string  `json:"title" binding:"required"`
		ImageURL        string  `json:"imageUrl" binding:"required"`
		Description     *string `json:"description"`
		Type            string  `json:"type" binding:"required"`
		TargetURL       *string `json:"targetUrl"`
		TargetProductID *string `json:"targetProductId"`
		TargetCategory  *string `json:"targetCategory"`
		StartDate       string  `json:"startDate" binding:"required"`
		EndDate         *string `json:"endDate"`
		IsActive        bool    `json:"isActive"`
		Priority        int     `json:"priority"`
		FestivalTag     *string `json:"festivalTag"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Parse start date
	startDate, err := parseDateTime(req.StartDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid start date format: " + err.Error(),
		})
		return
	}

	// Parse end date if provided
	var endDate *time.Time
	if req.EndDate != nil && *req.EndDate != "" {
		parsedEndDate, err := parseDateTime(*req.EndDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid end date format: " + err.Error(),
			})
			return
		}
		endDate = &parsedEndDate
	}

	banner := &models.Banner{
		Title:           req.Title,
		ImageURL:        req.ImageURL,
		Description:     req.Description,
		Type:            req.Type,
		TargetURL:       req.TargetURL,
		TargetProductID: req.TargetProductID,
		TargetCategory:  req.TargetCategory,
		StartDate:       startDate,
		EndDate:         endDate,
		IsActive:        req.IsActive,
		Priority:        req.Priority,
		FestivalTag:     req.FestivalTag,
	}

	if err := h.eventRepo.CreateBanner(c.Request.Context(), banner); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Banner created successfully",
		"data":    banner,
	})
}

// GetBanners gets all banners
func (h *EventHandler) GetBanners(c *gin.Context) {
	activeOnly := c.Query("activeOnly") == "true"

	var banners []models.Banner
	var err error

	if activeOnly {
		banners, err = h.eventRepo.GetActiveBanners(c.Request.Context())
	} else {
		banners, err = h.eventRepo.GetAllBanners(c.Request.Context())
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    banners,
	})
}

// GetActiveBanners gets currently active banners (public endpoint)
func (h *EventHandler) GetActiveBanners(c *gin.Context) {
	banners, err := h.eventRepo.GetActiveBanners(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    banners,
	})
}

// GetBanner gets a single banner by ID
func (h *EventHandler) GetBanner(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid banner ID",
		})
		return
	}

	banner, err := h.eventRepo.GetBannerByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Banner not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    banner,
	})
}

// UpdateBanner updates a banner (Admin only)
func (h *EventHandler) UpdateBanner(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid banner ID",
		})
		return
	}

	var req struct {
		Title           string  `json:"title"`
		ImageURL        string  `json:"imageUrl"`
		Description     *string `json:"description"`
		Type            string  `json:"type"`
		TargetURL       *string `json:"targetUrl"`
		TargetProductID *string `json:"targetProductId"`
		TargetCategory  *string `json:"targetCategory"`
		StartDate       string  `json:"startDate"`
		EndDate         *string `json:"endDate"`
		IsActive        bool    `json:"isActive"`
		Priority        int     `json:"priority"`
		FestivalTag     *string `json:"festivalTag"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Parse start date
	startDate, err := parseDateTime(req.StartDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid start date format: " + err.Error(),
		})
		return
	}

	// Parse end date if provided
	var endDate *time.Time
	if req.EndDate != nil && *req.EndDate != "" {
		parsedEndDate, err := parseDateTime(*req.EndDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid end date format: " + err.Error(),
			})
			return
		}
		endDate = &parsedEndDate
	}

	banner := &models.Banner{
		ID:              id,
		Title:           req.Title,
		ImageURL:        req.ImageURL,
		Description:     req.Description,
		Type:            req.Type,
		TargetURL:       req.TargetURL,
		TargetProductID: req.TargetProductID,
		TargetCategory:  req.TargetCategory,
		StartDate:       startDate,
		EndDate:         endDate,
		IsActive:        req.IsActive,
		Priority:        req.Priority,
		FestivalTag:     req.FestivalTag,
	}

	if err := h.eventRepo.UpdateBanner(c.Request.Context(), id, banner); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Banner updated successfully",
		"data":    banner,
	})
}

// DeleteBanner deletes a banner (Admin only)
func (h *EventHandler) DeleteBanner(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid banner ID",
		})
		return
	}

	if err := h.eventRepo.DeleteBanner(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Banner deleted successfully",
	})
}

// Theme endpoints

// CreateTheme creates a new theme (Admin only)
func (h *EventHandler) CreateTheme(c *gin.Context) {
	var req struct {
		Name            string  `json:"name" binding:"required"`
		Type            string  `json:"type" binding:"required"`
		PrimaryColor    string  `json:"primaryColor" binding:"required"`
		SecondaryColor  string  `json:"secondaryColor" binding:"required"`
		AccentColor     string  `json:"accentColor" binding:"required"`
		LogoURL         *string `json:"logoUrl"`
		BackgroundImage *string `json:"backgroundImage"`
		StartDate       *string `json:"startDate"`
		EndDate         *string `json:"endDate"`
		IsActive        bool    `json:"isActive"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Parse start date if provided
	var startDate *time.Time
	if req.StartDate != nil && *req.StartDate != "" {
		parsedStartDate, err := parseDateTime(*req.StartDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid start date format: " + err.Error(),
			})
			return
		}
		startDate = &parsedStartDate
	}

	// Parse end date if provided
	var endDate *time.Time
	if req.EndDate != nil && *req.EndDate != "" {
		parsedEndDate, err := parseDateTime(*req.EndDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid end date format: " + err.Error(),
			})
			return
		}
		endDate = &parsedEndDate
	}

	theme := &models.ThemeConfiguration{
		Name:            req.Name,
		Type:            req.Type,
		PrimaryColor:    req.PrimaryColor,
		SecondaryColor:  req.SecondaryColor,
		AccentColor:     req.AccentColor,
		LogoURL:         req.LogoURL,
		BackgroundImage: req.BackgroundImage,
		StartDate:       startDate,
		EndDate:         endDate,
		IsActive:        req.IsActive,
	}

	if err := h.eventRepo.CreateTheme(c.Request.Context(), theme); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Theme created successfully",
		"data":    theme,
	})
}

// GetThemes gets all themes (Admin only)
func (h *EventHandler) GetThemes(c *gin.Context) {
	themes, err := h.eventRepo.GetAllThemes(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    themes,
	})
}

// GetActiveTheme gets the currently active theme (public endpoint)
func (h *EventHandler) GetActiveTheme(c *gin.Context) {
	theme, err := h.eventRepo.GetActiveTheme(c.Request.Context())
	if err != nil {
		// Return default theme if none active
		defaultTheme := &models.ThemeConfiguration{
			Name:           "Default",
			Type:           "custom",
			PrimaryColor:   "#1B5E20",
			SecondaryColor: "#2E7D32",
			AccentColor:    "#4CAF50",
			IsActive:       true,
		}
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    defaultTheme,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    theme,
	})
}

// ActivateTheme activates a specific theme (Admin only)
func (h *EventHandler) ActivateTheme(c *gin.Context) {
	idParam := c.Param("id")
	
	// Try to parse as ObjectID first
	id, err := primitive.ObjectIDFromHex(idParam)
	if err != nil {
		// If not a valid ObjectID, treat it as a theme name/type (for predefined themes)
		// Try to find or create the predefined theme
		theme, err := h.eventRepo.GetThemeByName(c.Request.Context(), idParam)
		if err != nil {
			// Theme doesn't exist, try to create it from predefined template
			predefinedTheme := h.getPredefinedTheme(idParam)
			if predefinedTheme == nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"success": false,
					"error":   "Invalid theme ID or name",
				})
				return
			}
			
			// Create the predefined theme
			if err := h.eventRepo.CreateTheme(c.Request.Context(), predefinedTheme); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"success": false,
					"error":   err.Error(),
				})
				return
			}
			theme = predefinedTheme
		}
		id = theme.ID
	}

	if err := h.eventRepo.ActivateTheme(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Theme activated successfully",
	})
}

// getPredefinedTheme returns a predefined theme template by name
func (h *EventHandler) getPredefinedTheme(name string) *models.ThemeConfiguration {
	now := time.Now()
	
	switch name {
	case "diwali":
		return &models.ThemeConfiguration{
			Name:           "Diwali",
			Type:           "festival",
			PrimaryColor:   "#FF6F00",
			SecondaryColor: "#FFA726",
			AccentColor:    "#FFD54F",
			IsActive:       false,
		}
	case "christmas":
		return &models.ThemeConfiguration{
			Name:           "Christmas",
			Type:           "festival",
			PrimaryColor:   "#C62828",
			SecondaryColor: "#2E7D32",
			AccentColor:    "#FFD700",
			IsActive:       false,
		}
	case "valentine":
		return &models.ThemeConfiguration{
			Name:           "Valentine",
			Type:           "festival",
			PrimaryColor:   "#D81B60",
			SecondaryColor: "#EC407A",
			AccentColor:    "#F8BBD0",
			IsActive:       false,
		}
	case "newyear":
		return &models.ThemeConfiguration{
			Name:           "New Year",
			Type:           "festival",
			PrimaryColor:   "#1565C0",
			SecondaryColor: "#FFD700",
			AccentColor:    "#FFC107",
			IsActive:       false,
		}
	case "default":
		return &models.ThemeConfiguration{
			Name:           "Default",
			Type:           "custom",
			PrimaryColor:   "#1B5E20",
			SecondaryColor: "#2E7D32",
			AccentColor:    "#4CAF50",
			IsActive:       false,
		}
	default:
		_ = now // Avoid unused variable warning
		return nil
	}
}

// DeleteTheme deletes a theme (Admin only)
func (h *EventHandler) DeleteTheme(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid theme ID",
		})
		return
	}

	if err := h.eventRepo.DeleteTheme(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Theme deleted successfully",
	})
}

// Promotion endpoints

// CreatePromotion creates a new event promotion (Admin only)
func (h *EventHandler) CreatePromotion(c *gin.Context) {
	var req struct {
		EventID        string   `json:"eventId" binding:"required"`
		EventName      string   `json:"eventName" binding:"required"`
		Title          string   `json:"title" binding:"required"`
		Description    string   `json:"description" binding:"required"`
		DiscountType   string   `json:"discountType" binding:"required"`
		DiscountValue  float64  `json:"discountValue" binding:"required"`
		MinPurchase    *float64 `json:"minPurchase"`
		MaxDiscount    *float64 `json:"maxDiscount"`
		ApplicableTo   string   `json:"applicableTo" binding:"required"`
		Categories     []string `json:"categories"`
		ProductIDs     []string `json:"productIds"`
		StartDate      string   `json:"startDate" binding:"required"`
		EndDate        string   `json:"endDate" binding:"required"`
		IsActive       bool     `json:"isActive"`
		ShowAsPopup    bool     `json:"showAsPopup"`
		PopupImageURL  *string  `json:"popupImageUrl"`
		PopupFrequency string   `json:"popupFrequency"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	eventID, err := primitive.ObjectIDFromHex(req.EventID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid event ID",
		})
		return
	}

	// Parse start date
	startDate, err := parseDateTime(req.StartDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid start date format: " + err.Error(),
		})
		return
	}

	// Parse end date
	endDate, err := parseDateTime(req.EndDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid end date format: " + err.Error(),
		})
		return
	}

	promotion := &models.EventPromotion{
		EventID:        eventID,
		EventName:      req.EventName,
		Title:          req.Title,
		Description:    req.Description,
		DiscountType:   req.DiscountType,
		DiscountValue:  req.DiscountValue,
		MinPurchase:    req.MinPurchase,
		MaxDiscount:    req.MaxDiscount,
		ApplicableTo:   req.ApplicableTo,
		Categories:     req.Categories,
		ProductIDs:     req.ProductIDs,
		StartDate:      startDate,
		EndDate:        endDate,
		IsActive:       req.IsActive,
		ShowAsPopup:    req.ShowAsPopup,
		PopupImageURL:  req.PopupImageURL,
		PopupFrequency: req.PopupFrequency,
	}

	if err := h.eventRepo.CreatePromotion(c.Request.Context(), promotion); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Promotion created successfully",
		"data":    promotion,
	})
}

// GetActivePromotions gets currently active promotions (public endpoint)
func (h *EventHandler) GetActivePromotions(c *gin.Context) {
	promotions, err := h.eventRepo.GetActivePromotions(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    promotions,
	})
}

// GetPopupPromotions gets popup promotions (public endpoint)
func (h *EventHandler) GetPopupPromotions(c *gin.Context) {
	promotions, err := h.eventRepo.GetPopupPromotions(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    promotions,
	})
}

// DeletePromotion deletes a promotion (Admin only)
func (h *EventHandler) DeletePromotion(c *gin.Context) {
	id, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid promotion ID",
		})
		return
	}

	if err := h.eventRepo.DeletePromotion(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Promotion deleted successfully",
	})
}

