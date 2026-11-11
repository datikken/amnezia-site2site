<?php

declare(strict_types=1);

namespace DoctrineMigrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

final class Version20260101000000 extends AbstractMigration
{
    public function getDescription(): string
    {
        return 'Create app_user table for admin authentication';
    }

    public function up(Schema $schema): void
    {
        $table = $schema->createTable('app_user');
        $table->addColumn('id', 'integer', ['autoincrement' => true]);
        $table->addColumn('email', 'string', ['length' => 180]);
        $table->addColumn('roles', 'json');
        $table->addColumn('password', 'string', ['length' => 255]);
        $table->setPrimaryKey(['id']);
        $table->addUniqueIndex(['email'], 'UNIQ_8D93D649E7927C74');
    }

    public function down(Schema $schema): void
    {
        $schema->dropTable('app_user');
    }
}

