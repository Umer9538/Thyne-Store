package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SearchRequest represents a search request
type SearchRequest struct {
	Query      string                 `json:"query" form:"query"`
	Category   string                 `json:"category,omitempty" form:"category"`
	SubCategory string                `json:"subCategory,omitempty" form:"subCategory"`
	MinPrice   float64                `json:"minPrice,omitempty" form:"minPrice"`
	MaxPrice   float64                `json:"maxPrice,omitempty" form:"maxPrice"`
	MetalType  string                 `json:"metalType,omitempty" form:"metalType"`
	GemstoneType string               `json:"gemstoneType,omitempty" form:"gemstoneType"`
	Purity     string                 `json:"purity,omitempty" form:"purity"`
	Brand      string                 `json:"brand,omitempty" form:"brand"`
	Tags       []string               `json:"tags,omitempty" form:"tags"`
	InStock    *bool                  `json:"inStock,omitempty" form:"inStock"`
	Featured   *bool                  `json:"featured,omitempty" form:"featured"`
	OnSale     *bool                  `json:"onSale,omitempty" form:"onSale"`
	SortBy     string                 `json:"sortBy,omitempty" form:"sortBy"` // price_asc, price_desc, name_asc, name_desc, rating_desc, newest
	Page       int                    `json:"page,omitempty" form:"page"`
	Limit      int                    `json:"limit,omitempty" form:"limit"`
	Filters    map[string]interface{} `json:"filters,omitempty"`
}

// SearchResponse represents search results
type SearchResponse struct {
	Query       string          `json:"query"`
	Results     []Product       `json:"results"`
	Total       int64           `json:"total"`
	Page        int             `json:"page"`
	Limit       int             `json:"limit"`
	TotalPages  int             `json:"totalPages"`
	Facets      SearchFacets    `json:"facets"`
	Suggestions []string        `json:"suggestions,omitempty"`
	SearchTime  time.Duration   `json:"searchTime"`
	RelatedProducts []Product   `json:"relatedProducts,omitempty"`
}

// SearchFacets represents search facets for filtering
type SearchFacets struct {
	Categories   []FacetItem `json:"categories"`
	Brands       []FacetItem `json:"brands"`
	MetalTypes   []FacetItem `json:"metalTypes"`
	GemstoneTypes []FacetItem `json:"gemstoneTypes"`
	PriceRanges  []PriceRange `json:"priceRanges"`
	Purities     []FacetItem `json:"purities"`
	Tags         []FacetItem `json:"tags"`
}

// FacetItem represents a facet item with count
type FacetItem struct {
	Value string `json:"value"`
	Count int64  `json:"count"`
}

// PriceRange represents a price range facet
type PriceRange struct {
	Label string  `json:"label"`
	Min   float64 `json:"min"`
	Max   float64 `json:"max"`
	Count int64   `json:"count"`
}

// AutocompleteRequest represents an autocomplete request
type AutocompleteRequest struct {
	Query    string `json:"query" form:"query" binding:"required,min=1"`
	Category string `json:"category,omitempty" form:"category"`
	Limit    int    `json:"limit,omitempty" form:"limit"`
}

// AutocompleteResponse represents autocomplete results
type AutocompleteResponse struct {
	Query       string                `json:"query"`
	Suggestions []AutocompleteSuggestion `json:"suggestions"`
	Products    []ProductSuggestion      `json:"products"`
	Categories  []CategorySuggestion     `json:"categories"`
}

// AutocompleteSuggestion represents a search suggestion
type AutocompleteSuggestion struct {
	Text        string  `json:"text"`
	Type        string  `json:"type"` // "query", "brand", "category", "product"
	Score       float64 `json:"score"`
	Count       int64   `json:"count"`
	Highlighted string  `json:"highlighted"`
}

// ProductSuggestion represents a product suggestion
type ProductSuggestion struct {
	ID       primitive.ObjectID `json:"id"`
	Name     string             `json:"name"`
	Price    float64            `json:"price"`
	ImageURL string             `json:"imageUrl"`
	Category string             `json:"category"`
	Brand    string             `json:"brand"`
	Rating   float64            `json:"rating"`
}

// CategorySuggestion represents a category suggestion
type CategorySuggestion struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	ProductCount int64  `json:"productCount"`
	ImageURL    string `json:"imageUrl"`
}

// SearchAnalytics represents search analytics data
type SearchAnalytics struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Query        string             `json:"query" bson:"query"`
	UserID       *primitive.ObjectID `json:"userId,omitempty" bson:"userId,omitempty"`
	SessionID    string             `json:"sessionId" bson:"sessionId"`
	ResultCount  int64              `json:"resultCount" bson:"resultCount"`
	ClickedResults []string         `json:"clickedResults" bson:"clickedResults"`
	Filters      map[string]interface{} `json:"filters" bson:"filters"`
	SearchTime   int64              `json:"searchTime" bson:"searchTime"` // milliseconds
	UserAgent    string             `json:"userAgent" bson:"userAgent"`
	IPAddress    string             `json:"ipAddress" bson:"ipAddress"`
	Timestamp    time.Time          `json:"timestamp" bson:"timestamp"`
}

// PopularSearch represents popular search queries
type PopularSearch struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Query     string             `json:"query" bson:"query"`
	Count     int64              `json:"count" bson:"count"`
	Category  string             `json:"category,omitempty" bson:"category,omitempty"`
	UpdatedAt time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// SearchSynonym represents search synonyms for better matching
type SearchSynonym struct {
	ID       primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Term     string             `json:"term" bson:"term"`
	Synonyms []string           `json:"synonyms" bson:"synonyms"`
	Category string             `json:"category,omitempty" bson:"category,omitempty"`
	IsActive bool               `json:"isActive" bson:"isActive"`
	CreatedAt time.Time         `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time         `json:"updatedAt" bson:"updatedAt"`
}

// SearchConfig represents search configuration
type SearchConfig struct {
	ID                    primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	AutocompleteEnabled   bool               `json:"autocompleteEnabled" bson:"autocompleteEnabled"`
	SuggestionsEnabled    bool               `json:"suggestionsEnabled" bson:"suggestionsEnabled"`
	FacetsEnabled         bool               `json:"facetsEnabled" bson:"facetsEnabled"`
	AnalyticsEnabled      bool               `json:"analyticsEnabled" bson:"analyticsEnabled"`
	MaxSuggestions        int                `json:"maxSuggestions" bson:"maxSuggestions"`
	MaxAutocomplete       int                `json:"maxAutocomplete" bson:"maxAutocomplete"`
	MinQueryLength        int                `json:"minQueryLength" bson:"minQueryLength"`
	SearchFields          []SearchField      `json:"searchFields" bson:"searchFields"`
	BoostFields           []BoostField       `json:"boostFields" bson:"boostFields"`
	DefaultSortBy         string             `json:"defaultSortBy" bson:"defaultSortBy"`
	ResultsPerPage        int                `json:"resultsPerPage" bson:"resultsPerPage"`
	MaxResultsPerPage     int                `json:"maxResultsPerPage" bson:"maxResultsPerPage"`
	EnableSpellCheck      bool               `json:"enableSpellCheck" bson:"enableSpellCheck"`
	EnableFuzzySearch     bool               `json:"enableFuzzySearch" bson:"enableFuzzySearch"`
	CreatedAt             time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt             time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// SearchField represents a searchable field configuration
type SearchField struct {
	Field   string  `json:"field" bson:"field"`
	Weight  float64 `json:"weight" bson:"weight"`
	Enabled bool    `json:"enabled" bson:"enabled"`
}

// BoostField represents field boosting configuration
type BoostField struct {
	Field     string  `json:"field" bson:"field"`
	Boost     float64 `json:"boost" bson:"boost"`
	Condition string  `json:"condition,omitempty" bson:"condition,omitempty"`
}

// SearchIndex represents search index information
type SearchIndex struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name         string             `json:"name" bson:"name"`
	Collection   string             `json:"collection" bson:"collection"`
	Fields       []IndexField       `json:"fields" bson:"fields"`
	IsActive     bool               `json:"isActive" bson:"isActive"`
	IndexSize    int64              `json:"indexSize" bson:"indexSize"`
	DocumentCount int64             `json:"documentCount" bson:"documentCount"`
	LastUpdated  time.Time          `json:"lastUpdated" bson:"lastUpdated"`
	CreatedAt    time.Time          `json:"createdAt" bson:"createdAt"`
}

// IndexField represents an indexed field
type IndexField struct {
	Name     string  `json:"name" bson:"name"`
	Type     string  `json:"type" bson:"type"` // "text", "keyword", "numeric", "date"
	Weight   float64 `json:"weight" bson:"weight"`
	Analyzer string  `json:"analyzer,omitempty" bson:"analyzer,omitempty"`
}

// TrendingSearch represents trending search data
type TrendingSearch struct {
	Query     string    `json:"query"`
	Count     int64     `json:"count"`
	Growth    float64   `json:"growth"` // percentage growth
	Category  string    `json:"category,omitempty"`
	Period    string    `json:"period"` // "daily", "weekly", "monthly"
	Timestamp time.Time `json:"timestamp"`
}

// SearchFilter represents dynamic search filters
type SearchFilter struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Name        string             `json:"name" bson:"name"`
	Field       string             `json:"field" bson:"field"`
	Type        string             `json:"type" bson:"type"` // "range", "select", "checkbox", "radio"
	Options     []FilterOption     `json:"options" bson:"options"`
	IsActive    bool               `json:"isActive" bson:"isActive"`
	DisplayOrder int               `json:"displayOrder" bson:"displayOrder"`
	Category    string             `json:"category,omitempty" bson:"category,omitempty"`
	CreatedAt   time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// FilterOption represents a filter option
type FilterOption struct {
	Label string      `json:"label" bson:"label"`
	Value interface{} `json:"value" bson:"value"`
	Count int64       `json:"count,omitempty" bson:"count,omitempty"`
}

// SearchPersonalization represents user search personalization
type SearchPersonalization struct {
	ID               primitive.ObjectID         `json:"id" bson:"_id,omitempty"`
	UserID           primitive.ObjectID         `json:"userId" bson:"userId"`
	PreferredCategories []string                `json:"preferredCategories" bson:"preferredCategories"`
	PreferredBrands     []string                `json:"preferredBrands" bson:"preferredBrands"`
	PriceRange          PriceRange              `json:"priceRange" bson:"priceRange"`
	SearchHistory       []string                `json:"searchHistory" bson:"searchHistory"`
	ClickedProducts     []primitive.ObjectID    `json:"clickedProducts" bson:"clickedProducts"`
	ViewedProducts      []primitive.ObjectID    `json:"viewedProducts" bson:"viewedProducts"`
	PurchasedProducts   []primitive.ObjectID    `json:"purchasedProducts" bson:"purchasedProducts"`
	Preferences         map[string]interface{}  `json:"preferences" bson:"preferences"`
	UpdatedAt           time.Time               `json:"updatedAt" bson:"updatedAt"`
	CreatedAt           time.Time               `json:"createdAt" bson:"createdAt"`
}

// SearchExport represents search export data
type SearchExport struct {
	Query       string            `json:"query"`
	Filters     map[string]interface{} `json:"filters"`
	Results     []primitive.ObjectID `json:"results"`
	Total       int64             `json:"total"`
	ExportedAt  time.Time         `json:"exportedAt"`
	ExportedBy  primitive.ObjectID `json:"exportedBy"`
	Format      string            `json:"format"` // "csv", "excel", "json"
}

// SearchCache represents cached search results
type SearchCache struct {
	ID         primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	QueryHash  string             `json:"queryHash" bson:"queryHash"`
	Query      SearchRequest      `json:"query" bson:"query"`
	Results    SearchResponse     `json:"results" bson:"results"`
	CreatedAt  time.Time          `json:"createdAt" bson:"createdAt"`
	ExpiresAt  time.Time          `json:"expiresAt" bson:"expiresAt"`
	HitCount   int64              `json:"hitCount" bson:"hitCount"`
	LastHit    time.Time          `json:"lastHit" bson:"lastHit"`
}

// SpellingSuggestion represents spelling correction suggestions
type SpellingSuggestion struct {
	Original   string   `json:"original"`
	Suggestions []string `json:"suggestions"`
	Confidence float64  `json:"confidence"`
}

// SearchRecommendation represents search-based recommendations
type SearchRecommendation struct {
	Type        string               `json:"type"` // "similar_searches", "popular_in_category", "trending"
	Title       string               `json:"title"`
	Products    []ProductSuggestion  `json:"products"`
	Queries     []string             `json:"queries"`
	Reason      string               `json:"reason"`
}

// Advanced search operators
const (
	SearchOperatorAND     = "AND"
	SearchOperatorOR      = "OR"
	SearchOperatorNOT     = "NOT"
	SearchOperatorEXACT   = "EXACT"
	SearchOperatorWILDCARD = "WILDCARD"
	SearchOperatorFUZZY   = "FUZZY"
)

// Search result types
const (
	SearchResultTypeProduct  = "product"
	SearchResultTypeCategory = "category"
	SearchResultTypeBrand    = "brand"
	SearchResultTypeContent  = "content"
)

// Sort options
const (
	SortByRelevance   = "relevance"
	SortByPriceAsc    = "price_asc"
	SortByPriceDesc   = "price_desc"
	SortByNameAsc     = "name_asc"
	SortByNameDesc    = "name_desc"
	SortByRatingDesc  = "rating_desc"
	SortByNewest      = "newest"
	SortByBestSeller  = "best_seller"
	SortByDiscount    = "discount"
	SortByPopularity  = "popularity"
)

// Filter types
const (
	FilterTypeRange     = "range"
	FilterTypeSelect    = "select"
	FilterTypeCheckbox  = "checkbox"
	FilterTypeRadio     = "radio"
	FilterTypeDate      = "date"
	FilterTypeBoolean   = "boolean"
	FilterTypeMultiSelect = "multi_select"
)

// GetDefaultSearchConfig returns default search configuration
func GetDefaultSearchConfig() *SearchConfig {
	return &SearchConfig{
		AutocompleteEnabled:   true,
		SuggestionsEnabled:    true,
		FacetsEnabled:         true,
		AnalyticsEnabled:      true,
		MaxSuggestions:        10,
		MaxAutocomplete:       8,
		MinQueryLength:        2,
		DefaultSortBy:         SortByRelevance,
		ResultsPerPage:        20,
		MaxResultsPerPage:     100,
		EnableSpellCheck:      true,
		EnableFuzzySearch:     true,
		SearchFields: []SearchField{
			{Field: "name", Weight: 3.0, Enabled: true},
			{Field: "description", Weight: 1.0, Enabled: true},
			{Field: "tags", Weight: 2.0, Enabled: true},
			{Field: "brand", Weight: 1.5, Enabled: true},
			{Field: "category", Weight: 1.5, Enabled: true},
			{Field: "metalType", Weight: 1.0, Enabled: true},
			{Field: "gemstoneType", Weight: 1.0, Enabled: true},
		},
		BoostFields: []BoostField{
			{Field: "featured", Boost: 2.0, Condition: "true"},
			{Field: "inStock", Boost: 1.5, Condition: "true"},
			{Field: "rating", Boost: 1.2, Condition: ">4.0"},
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}