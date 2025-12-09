package repository

import (
    "context"
    "errors"
    "time"

    "thyne-jewels-backend/internal/models"

    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)


type userRepository struct {
	collection *mongo.Collection
}

func NewUserRepository(db *mongo.Database) UserRepository {
	return &userRepository{
		collection: db.Collection("users"),
	}
}

func (r *userRepository) Create(ctx context.Context, user *models.User) error {
    if ctx == nil {
        ctx = context.Background()
    }
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()
	user.IsActive = true
	user.IsVerified = false
	user.IsAdmin = false

	_, err := r.collection.InsertOne(ctx, user)
	return err
}

func (r *userRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.User, error) {
    if ctx == nil {
        ctx = context.Background()
    }
	var user models.User
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(ctx context.Context, email string) (*models.User, error) {
    if ctx == nil {
        ctx = context.Background()
    }
	var user models.User
	err := r.collection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByPhone(ctx context.Context, phone string) (*models.User, error) {
    if ctx == nil {
        ctx = context.Background()
    }
	var user models.User
	err := r.collection.FindOne(ctx, bson.M{"phone": phone}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(ctx context.Context, user *models.User) error {
	user.UpdatedAt = time.Now()
	
	filter := bson.M{"_id": user.ID}
	update := bson.M{
		"$set": bson.M{
			"name":         user.Name,
			"email":        user.Email,
			"phone":        user.Phone,
			"profileImage": user.ProfileImage,
			"addresses":    user.Addresses,
			"isActive":     user.IsActive,
			"isVerified":   user.IsVerified,
			"isAdmin":      user.IsAdmin,
			"updatedAt":    user.UpdatedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *userRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}
	_, err := r.collection.DeleteOne(ctx, filter)
	return err
}

func (r *userRepository) UpdatePassword(ctx context.Context, id primitive.ObjectID, hashedPassword string) error {
	filter := bson.M{"_id": id}
	update := bson.M{
		"$set": bson.M{
			"password":  hashedPassword,
			"updatedAt": time.Now(),
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *userRepository) UpdateProfile(ctx context.Context, id primitive.ObjectID, updates *models.UpdateProfileRequest) error {
	filter := bson.M{"_id": id}
	update := bson.M{"$set": bson.M{"updatedAt": time.Now()}}

	if updates.Name != "" {
		update["$set"].(bson.M)["name"] = updates.Name
	}
	if updates.Phone != "" {
		update["$set"].(bson.M)["phone"] = updates.Phone
	}
	if updates.ProfileImage != "" {
		update["$set"].(bson.M)["profileImage"] = updates.ProfileImage
	}
	if updates.Addresses != nil {
		update["$set"].(bson.M)["addresses"] = updates.Addresses
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *userRepository) AddAddress(ctx context.Context, userID primitive.ObjectID, address models.Address) error {
	filter := bson.M{"_id": userID}
	
	// Use aggregation pipeline to handle null addresses field
	pipeline := []bson.M{
		{
			"$set": bson.M{
				"addresses": bson.M{
					"$ifNull": []interface{}{"$addresses", []models.Address{}},
				},
			},
		},
		{
			"$set": bson.M{
				"addresses": bson.M{
					"$concatArrays": []interface{}{"$addresses", []models.Address{address}},
				},
				"updatedAt": time.Now(),
			},
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, pipeline)
	return err
}

func (r *userRepository) UpdateAddress(ctx context.Context, userID primitive.ObjectID, addressID primitive.ObjectID, address models.Address) error {
	filter := bson.M{
		"_id":            userID,
		"addresses._id":  addressID,
	}
	update := bson.M{
		"$set": bson.M{
			"addresses.$": address,
			"updatedAt":   time.Now(),
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *userRepository) DeleteAddress(ctx context.Context, userID primitive.ObjectID, addressID primitive.ObjectID) error {
	filter := bson.M{"_id": userID}
	update := bson.M{
		"$pull": bson.M{"addresses": bson.M{"_id": addressID}},
		"$set":  bson.M{"updatedAt": time.Now()},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *userRepository) SetDefaultAddress(ctx context.Context, userID primitive.ObjectID, addressID primitive.ObjectID) error {
	// Get the user first
	user, err := r.GetByID(ctx, userID)
	if err != nil {
		return err
	}

	// Update all addresses to set isDefault to false
	for i := range user.Addresses {
		user.Addresses[i].IsDefault = false
	}

	// Find and set the specified address as default
	for i := range user.Addresses {
		if user.Addresses[i].ID == addressID {
			user.Addresses[i].IsDefault = true
			break
		}
	}

	// Update the user
	return r.Update(ctx, user)
}

func (r *userRepository) GetAll(ctx context.Context, page, limit int) ([]models.User, int64, error) {
	// Count total documents
	total, err := r.collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, 0, err
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find users with pagination
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	// Decode documents manually to handle malformed addresses
	var users []models.User
	for cursor.Next(ctx) {
		var rawDoc bson.M
		if err := cursor.Decode(&rawDoc); err != nil {
			continue // Skip malformed documents
		}

		user := r.parseUserFromRawDoc(rawDoc)
		users = append(users, user)
	}

	if err := cursor.Err(); err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

// parseUserFromRawDoc safely parses a raw BSON document into a User struct
// This handles cases where addresses might be stored as strings instead of objects
func (r *userRepository) parseUserFromRawDoc(doc bson.M) models.User {
	user := models.User{}

	// Parse ID
	if id, ok := doc["_id"].(primitive.ObjectID); ok {
		user.ID = id
	}

	// Parse basic fields
	if name, ok := doc["name"].(string); ok {
		user.Name = name
	}
	if email, ok := doc["email"].(string); ok {
		user.Email = email
	}
	if phone, ok := doc["phone"].(string); ok {
		user.Phone = phone
	}
	if password, ok := doc["password"].(string); ok {
		user.Password = password
	}
	if profileImage, ok := doc["profileImage"].(string); ok {
		user.ProfileImage = profileImage
	}
	if isActive, ok := doc["isActive"].(bool); ok {
		user.IsActive = isActive
	}
	if isVerified, ok := doc["isVerified"].(bool); ok {
		user.IsVerified = isVerified
	}
	if isAdmin, ok := doc["isAdmin"].(bool); ok {
		user.IsAdmin = isAdmin
	}

	// Parse dates
	if createdAt, ok := doc["createdAt"].(primitive.DateTime); ok {
		user.CreatedAt = createdAt.Time()
	}
	if updatedAt, ok := doc["updatedAt"].(primitive.DateTime); ok {
		user.UpdatedAt = updatedAt.Time()
	}

	// Safely parse addresses - handle both proper objects and strings
	user.Addresses = []models.Address{} // Default to empty array
	if addresses, ok := doc["addresses"].(primitive.A); ok {
		for _, addrItem := range addresses {
			// Try to parse as proper Address object
			if addrDoc, ok := addrItem.(bson.M); ok {
				addr := r.parseAddressFromRawDoc(addrDoc)
				user.Addresses = append(user.Addresses, addr)
			}
			// If it's a string or other type, skip it (malformed data)
		}
	}

	return user
}

// parseAddressFromRawDoc safely parses a raw BSON document into an Address struct
func (r *userRepository) parseAddressFromRawDoc(doc bson.M) models.Address {
	addr := models.Address{}

	if id, ok := doc["_id"].(primitive.ObjectID); ok {
		addr.ID = id
	}
	if userID, ok := doc["userId"].(primitive.ObjectID); ok {
		addr.UserID = userID
	}
	if houseNoFloor, ok := doc["houseNoFloor"].(string); ok {
		addr.HouseNoFloor = houseNoFloor
	}
	if buildingBlock, ok := doc["buildingBlock"].(string); ok {
		addr.BuildingBlock = buildingBlock
	}
	if landmarkArea, ok := doc["landmarkArea"].(string); ok {
		addr.LandmarkArea = landmarkArea
	}
	if city, ok := doc["city"].(string); ok {
		addr.City = city
	}
	if state, ok := doc["state"].(string); ok {
		addr.State = state
	}
	if pincode, ok := doc["pincode"].(string); ok {
		addr.Pincode = pincode
	}
	if country, ok := doc["country"].(string); ok {
		addr.Country = country
	}
	if label, ok := doc["label"].(string); ok {
		addr.Label = label
	}
	if recipientName, ok := doc["recipientName"].(string); ok {
		addr.RecipientName = recipientName
	}
	if recipientPhone, ok := doc["recipientPhone"].(string); ok {
		addr.RecipientPhone = recipientPhone
	}
	if isDefault, ok := doc["isDefault"].(bool); ok {
		addr.IsDefault = isDefault
	}
	if street, ok := doc["street"].(string); ok {
		addr.Street = street
	}
	if zipCode, ok := doc["zipCode"].(string); ok {
		addr.ZipCode = zipCode
	}
	if createdAt, ok := doc["createdAt"].(primitive.DateTime); ok {
		addr.CreatedAt = createdAt.Time()
	}
	if updatedAt, ok := doc["updatedAt"].(primitive.DateTime); ok {
		addr.UpdatedAt = updatedAt.Time()
	}

	return addr
}

func (r *userRepository) Search(ctx context.Context, query string, page, limit int) ([]models.User, int64, error) {
	// Create search filter
	filter := bson.M{
		"$or": []bson.M{
			{"name": bson.M{"$regex": query, "$options": "i"}},
			{"email": bson.M{"$regex": query, "$options": "i"}},
			{"phone": bson.M{"$regex": query, "$options": "i"}},
		},
	}

	// Count total documents
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Calculate skip
	skip := (page - 1) * limit

	// Find users with pagination
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	// Decode documents manually to handle malformed addresses
	var users []models.User
	for cursor.Next(ctx) {
		var rawDoc bson.M
		if err := cursor.Decode(&rawDoc); err != nil {
			continue // Skip malformed documents
		}

		user := r.parseUserFromRawDoc(rawDoc)
		users = append(users, user)
	}

	if err := cursor.Err(); err != nil {
		return nil, 0, err
	}

	return users, total, nil
}
