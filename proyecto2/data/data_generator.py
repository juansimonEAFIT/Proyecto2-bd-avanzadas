#!/usr/bin/env python3
"""
SOCIAL NETWORK - Generador de Datos Sintéticos
Genera datos realistas para pruebas de bases de datos distribuidas
"""

import random
import string
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
import json

class DataGenerator:
    """Generador de datos sintéticos para red social distribuida"""

    NAMES_FIRST = ['Juan', 'María', 'Carlos', 'Ana', 'Luis', 'Rosa', 'Pedro', 'Sofia', 'Miguel', 'Laura']
    NAMES_LAST = ['García', 'López', 'Rodríguez', 'Martínez', 'Pérez', 'Sánchez', 'Torres', 'Ramírez', 'Flores', 'Rivera']
    
    LOCATIONS = ['Bogotá, Colombia', 'Medellín, Colombia', 'Cali, Colombia', 'Barranquilla, Colombia', 'Cartagena, Colombia']
    
    HASHTAGS = ['#social', '#network', '#distributed', '#database', '#awesome', '#love', '#photography', '#travel', '#food', '#tech']
    
    BIO_TEMPLATES = [
        "Passionate developer interested in databases",
        "Entrepreneur and coffee lover",
        "Photographer and traveler",
        "Software engineer at {city}",
        "Thinking about distributed systems",
        "Always learning new technologies",
        "Friend of nature and technology"
    ]

    def __init__(self, seed: int = 42):
        random.seed(seed)
        self.seed = seed

    def generate_username(self, user_id: int) -> str:
        """Genera un nombre de usuario único"""
        return f"user_{user_id}_{self._random_string(6)}"

    def generate_email(self, user_id: int) -> str:
        """Genera un email único"""
        username = f"user_{user_id}_{self._random_string(4)}"
        domains = ['gmail.com', 'example.com', 'test.com', 'social.com']
        return f"{username}@{random.choice(domains)}"

    def generate_full_name(self) -> str:
        """Genera un nombre completo realista"""
        first = random.choice(self.NAMES_FIRST)
        last = random.choice(self.NAMES_LAST)
        return f"{first} {last}"

    def generate_bio(self) -> str:
        """Genera una biografía"""
        template = random.choice(self.BIO_TEMPLATES)
        city = random.choice(self.LOCATIONS).split(',')[0]
        return template.format(city=city)

    def generate_post_content(self, post_id: int) -> str:
        """Genera contenido de un post"""
        hashtags = ' '.join(random.sample(self.HASHTAGS, k=random.randint(2, 4)))
        templates = [
            f"Check this out! Post #{post_id} {hashtags}",
            f"Amazing day! {hashtags}",
            f"Sharing my thoughts... {hashtags}",
            f"What a moment! {hashtags}",
            f"Feeling good about this {hashtags}"
        ]
        return random.choice(templates)

    def generate_comment_content(self) -> str:
        """Genera contenido de comentario"""
        templates = [
            "Great post! Love this!",
            "Amazing! Thanks for sharing!",
            "This is awesome!",
            "Wow! Super interesting!",
            "Very nice, thanks!",
            "Totally agree!",
            "WOW!",
            "This deserves more likes!",
        ]
        return random.choice(templates)

    def generate_random_timestamp(self, days_back: int = 90) -> str:
        """Genera una fecha aleatoria en los últimos N días"""
        end = datetime.now()
        start = end - timedelta(days=days_back)
        random_date = start + timedelta(seconds=random.randint(0, int((end - start).total_seconds())))
        return random_date.isoformat()

    def get_random_location(self) -> str:
        """Retorna una ubicación aleatoria"""
        return random.choice(self.LOCATIONS)

    def _random_string(self, length: int = 8) -> str:
        """Genera una cadena aleatoria de caracteres"""
        return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

    def generate_users_batch(self, count: int = 1000, start_id: int = 1) -> List[Dict]:
        """Genera un lote de usuarios"""
        users = []
        for i in range(count):
            user_id = start_id + i
            users.append({
                'user_id': user_id,
                'username': self.generate_username(user_id),
                'email': self.generate_email(user_id),
                'full_name': self.generate_full_name(),
                'bio': self.generate_bio(),
                'follower_count': random.randint(0, 100000),
                'following_count': random.randint(0, 50000),
                'post_count': random.randint(0, 10000),
                'is_verified': random.random() > 0.95,
                'is_private': random.random() > 0.7,
                'created_at': self.generate_random_timestamp(days_back=365)
            })
        return users

    def generate_posts_batch(self, count: int = 10000, max_user_id: int = 1000) -> List[Dict]:
        """Genera un lote de posts"""
        posts = []
        for i in range(count):
            posts.append({
                'post_id': i,
                'user_id': random.randint(1, max_user_id),
                'content': self.generate_post_content(i),
                'location': self.get_random_location(),
                'like_count': random.randint(0, 10000),
                'comment_count': random.randint(0, 1000),
                'share_count': random.randint(0, 100),
                'is_deleted': random.random() > 0.95,
                'created_at': self.generate_random_timestamp(days_back=90)
            })
        return posts

    def generate_comments_batch(self, count: int = 5000, max_post_id: int = 10000, max_user_id: int = 1000) -> List[Dict]:
        """Genera un lote de comentarios"""
        comments = []
        for i in range(count):
            comments.append({
                'comment_id': i,
                'post_id': random.randint(1, max_post_id),
                'user_id': random.randint(1, max_user_id),
                'content': self.generate_comment_content(),
                'like_count': random.randint(0, 1000),
                'is_deleted': random.random() > 0.95,
                'created_at': self.generate_random_timestamp(days_back=30)
            })
        return comments

    def generate_followers_batch(self, count: int = 5000, max_user_id: int = 1000) -> List[Dict]:
        """Genera un lote de relaciones de followers"""
        followers = []
        created = set()
        
        for _ in range(count):
            while True:
                follower_id = random.randint(1, max_user_id)
                following_id = random.randint(1, max_user_id)
                
                # Evitar auto-follow y duplicados
                if follower_id != following_id and (follower_id, following_id) not in created:
                    created.add((follower_id, following_id))
                    followers.append({
                        'follower_id': follower_id,
                        'following_id': following_id,
                        'created_at': self.generate_random_timestamp(days_back=60)
                    })
                    break
        
        return followers

    def generate_likes_batch(self, count: int = 10000, max_post_id: int = 10000, max_user_id: int = 1000) -> List[Dict]:
        """Genera un lote de likes en posts"""
        likes = []
        created = set()
        
        for i in range(count):
            while True:
                post_id = random.randint(1, max_post_id)
                user_id = random.randint(1, max_user_id)
                
                if (post_id, user_id) not in created:
                    created.add((post_id, user_id))
                    likes.append({
                        'like_id': i,
                        'post_id': post_id,
                        'user_id': user_id,
                        'created_at': self.generate_random_timestamp(days_back=30)
                    })
                    break
        
        return likes

    def export_to_csv(self, data: List[Dict], filename: str):
        """Exporta datos a CSV"""
        if not data:
            return
        
        import csv
        keys = data[0].keys()
        with open(filename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(data)
        print(f"Exported {len(data)} records to {filename}")

    def export_to_json(self, data: List[Dict], filename: str):
        """Exporta datos a JSON"""
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Exported {len(data)} records to {filename}")


if __name__ == "__main__":
    # Ejemplo de uso
    generator = DataGenerator(seed=42)
    
    # Generar usuarios
    users = generator.generate_users_batch(count=100)
    generator.export_to_json(users, 'users.json')
    
    # Generar posts
    posts = generator.generate_posts_batch(count=500, max_user_id=100)
    generator.export_to_json(posts, 'posts.json')
    
    # Generar comentarios
    comments = generator.generate_comments_batch(count=300, max_post_id=500, max_user_id=100)
    generator.export_to_json(comments, 'comments.json')
    
    # Generar followers
    followers = generator.generate_followers_batch(count=200, max_user_id=100)
    generator.export_to_json(followers, 'followers.json')
    
    # Generar likes
    likes = generator.generate_likes_batch(count=400, max_post_id=500, max_user_id=100)
    generator.export_to_json(likes, 'likes.json')
    
    print("Data generation completed!")

