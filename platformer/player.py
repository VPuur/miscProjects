import pygame
from support import import_folder

class Player(pygame.sprite.Sprite):
    def __init__(self, pos, u, d, l, r):
        super().__init__()
        self.import_character_assets()
        self.frame_index = 0
        self.animation_speed = 0.15
        print(self.animations)
        self.image = self.animations['idle'][self.frame_index]
        self.rect = self.image.get_rect(topleft = pos)

        # player movement
        self.direction = pygame.math.Vector2(0, 0)
        self.speed = 4
        self.gravity = 0.6
        self.jump_speed = -15
        self.on_ground = False
        self.on_ground_anim = False
        self.on_ceiling = False
        self.on_left = False
        self.on_right = False
        self.u = u
        self.d = d
        self.l = l
        self.r = r

        # player status
        self.status = 'idle'
        self.facing_right = True

    def import_character_assets(self):
        character_path = '/home/veikka/projects/python/platformer/graphics/character/'
        self.animations = {'idle':[], 'run':[], 'jump':[], 'fall':[]}

        for animation in self.animations.keys():
            full_path = character_path + animation
            self.animations[animation] = import_folder(full_path)

    def animate(self):
        animation = self.animations[self.status]

        self.frame_index += self.animation_speed
        if self.frame_index >= len(animation):
            self.frame_index = 0

        image = animation[int(self.frame_index)]

        if self.facing_right:
            self.image = image
        else:
            flipped_image = pygame.transform.flip(image, True, False)
            self.image = flipped_image

        if self.on_ground:
            self.rect = self.image.get_rect(midbottom = self.rect.midbottom)
        elif self.on_ceiling:
            self.rect = self.image.get_rect(midtop = self.rect.midtop)
        else:
            self.rect = self.image.get_rect(center = self.rect.center)

    def get_input(self):
        keys = pygame.key.get_pressed()

        # walking
        if keys[self.r]:
            self.direction.x = 1
            self.facing_right = True
        elif keys[self.l]:
            self.direction.x = -1
            self.facing_right = False
        else:
            self.direction.x = 0
        # jumping
        if keys [self.u]:
            if self.on_ground:
                self.jump()

    def get_status(self):
        if self.direction.y < 0:
            self.status = 'jump'
        elif self.direction.y > 1:
            self.status = 'fall'
        elif self.direction.x < 0:
            self.status = 'run'
        elif self.direction.x > 0:
            self.status = 'run'
        else:
            self.status = 'idle'


    def apply_gravity(self):
        self.direction.y += self.gravity
        self.rect.y += self.direction.y

    def jump(self):
        self.direction.y = self.jump_speed

    def set_on_ground(self, on_ground):
        self.on_ground = on_ground

    def update(self):
        self.get_input()
        self.get_status()
        self.animate()