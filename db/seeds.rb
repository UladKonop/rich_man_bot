# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Initial categories
categories = [
  { name: 'Продукты', icon: '🛒' },
  { name: 'Транспорт', icon: '🚗' },
  { name: 'Жилье', icon: '🏠' },
  { name: 'Развлечения', icon: '🎮' },
  { name: 'Здоровье', icon: '💊' },
  { name: 'Одежда', icon: '👕' },
  { name: 'Образование', icon: '📚' },
  { name: 'Подарки', icon: '🎁' },
  { name: 'Другое', icon: '📦' }
]

categories.each do |category|
  Category.find_or_create_by!(name: category[:name]) do |c|
    c.icon = category[:icon]
  end
end
