package services

import (
	"context"
	"strings"
	"time"

	"thyne-jewels-backend/internal/models"
	"thyne-jewels-backend/internal/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type CategoryService interface {
	CreateCategory(ctx context.Context, name, description string) (*models.Category, error)
	UpdateCategory(ctx context.Context, id string, name, description string) (*models.Category, error)
	DeleteCategory(ctx context.Context, id string) error
	GetAllCategories(ctx context.Context) ([]models.Category, error)
}

type categoryService struct {
	repo repository.CategoryRepository
}

func NewCategoryService(repo repository.CategoryRepository) CategoryService {
	return &categoryService{repo: repo}
}

func (s *categoryService) CreateCategory(ctx context.Context, name, description string) (*models.Category, error) {
	cat := &models.Category{
		ID:          primitive.NewObjectID(),
		Name:        name,
		Slug:        generateSlug(name),
		Description: description,
		IsActive:    true,
		SortOrder:   0,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}
	if err := s.repo.Create(ctx, cat); err != nil {
		return nil, err
	}
	return cat, nil
}

func (s *categoryService) UpdateCategory(ctx context.Context, id string, name, description string) (*models.Category, error) {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil { return nil, err }
	existing, err := s.repo.GetByID(ctx, objID)
	if err != nil { return nil, err }
	existing.Name = name
	existing.Slug = generateSlug(name)
	existing.Description = description
	existing.UpdatedAt = time.Now()
	if err := s.repo.Update(ctx, existing); err != nil {
		return nil, err
	}
	return existing, nil
}

func (s *categoryService) DeleteCategory(ctx context.Context, id string) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil { return err }
	return s.repo.Delete(ctx, objID)
}

func (s *categoryService) GetAllCategories(ctx context.Context) ([]models.Category, error) {
    categories, _, err := s.repo.List(ctx, 1, 1000)
    return categories, err
}

func generateSlug(name string) string {
	return strings.ToLower(strings.ReplaceAll(strings.TrimSpace(name), " ", "-"))
}


