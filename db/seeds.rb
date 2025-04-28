# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Create default user categories for new users
DEFAULT_CATEGORIES = [
  { name: 'Еда', emoji: '🍔' },
  { name: 'Транспорт', emoji: '🚗' },
  { name: 'Жилье', emoji: '🏠' },
  { name: 'Развлечения', emoji: '🎮' },
  { name: 'Здоровье', emoji: '💊' },
  { name: 'Одежда', emoji: '👕' },
  { name: 'Образование', emoji: '📚' },
  { name: 'Другое', emoji: '📦' }
].freeze

# Note: These categories will be created for each user when they register
# through the User model's after_create callback
