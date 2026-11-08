import pygame
from tiles import Tile
from player import Player
from settings import tile_size, screen_width

class Level:
    def __init__(self, level_data, surface):
        self.display_surface = surface
        self.setup_level(level_data)
        self.world_shift = 0

    def setup_level(self, layout):
        self.tiles = pygame.sprite.Group()
        self.player = pygame.sprite.GroupSingle()
        self.player2 = pygame.sprite.GroupSingle()

        for row_index, row in enumerate(layout):
            for col_index, cell in enumerate(row):
                x = col_index * tile_size
                y = row_index * tile_size

                if cell == 'X':
                    tile = Tile((x, y), tile_size)
                    self.tiles.add(tile)
                if cell == 'P':
                    player = Player((x, y), pygame.K_UP, pygame.K_DOWN, pygame.K_LEFT, pygame.K_RIGHT)
                    self.player.add(player)
                if cell == 'R':
                    player = Player((x, y), pygame.K_w, pygame.K_s, pygame.K_a, pygame.K_d)
                    self.player2.add(player)

    def scroll_x(self, player):
        player_sprite = player.sprite
        player_x = player_sprite.rect.centerx
        direction_x = player_sprite.direction.x

        if player_x < screen_width / 5 and direction_x < 0:
            self.world_shift = 5
            player_sprite.speed = 0

        elif player_x > screen_width - (screen_width / 5) and direction_x > 0:
            self.world_shift = - 5
            player_sprite.speed = 0

        else:
            self.world_shift = 0
            player_sprite.speed = 5

    def horizontal_movement_collision(self, player):
        player_sprite = player.sprite
        player_sprite.rect.x += player_sprite.direction.x * player_sprite.speed

        for sprite in self.tiles.sprites():
            if sprite.rect.colliderect(player_sprite.rect):
                if player_sprite.direction.x < 0:
                    player_sprite.rect.left = sprite.rect.right
                elif player_sprite.direction.x > 0:
                    player_sprite.rect.right = sprite.rect.left

    def vertical_movement_collision(self, player):
        player_sprite = player.sprite
        player_sprite.apply_gravity()
        on_ground = False

        for sprite in self.tiles.sprites():
            if sprite.rect.colliderect(player_sprite.rect):
                if player_sprite.direction.y > 0:
                    player_sprite.rect.bottom = sprite.rect.top
                    player_sprite.direction.y = 0
                    player.on_ground_anim = True
                elif player_sprite.direction.y < 0:
                    player_sprite.rect.top = sprite.rect.bottom
                    player_sprite.direction.y = 0
                    player.on_ceiling = True

            if sprite.rect.top == player_sprite.rect.bottom \
                    and sprite.rect.left <= player_sprite.rect.right \
                    and sprite.rect.right >= player_sprite.rect.left:
                on_ground = True

        if player_sprite.on_ground_anim and player_sprite.direction.y < 0 or player_sprite.direction.y > 1:
            player_sprite.on_ground_anim = False
        if player_sprite.on_ground_anim and player_sprite.direction.y > 0:
            player_sprite.on_ceiling = False

        player_sprite.set_on_ground(on_ground)


    def run(self):
        # level tiles
        self.tiles.update(self.world_shift)
        self.tiles.draw(self.display_surface)
        self.scroll_x(self.player)
        self.scroll_x(self.player2)

        # player
        self.player.update()
        self.player2.update()
        self.player.draw(self.display_surface)
        self.player2.draw(self.display_surface)
        self.vertical_movement_collision(self.player)
        self.vertical_movement_collision(self.player2)
        self.horizontal_movement_collision(self.player)
        self.horizontal_movement_collision(self.player2)