<?php

namespace App\Modules\Dictionaries\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Dictionary table. Source of truth is the fixed enum list.
 *
 * @property string $code
 * @property string|null $description
 */
final class ProjectRole extends Model
{
    protected $table = 'project_roles';
    protected $primaryKey = 'code';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'code',
        'description',
    ];

    public $timestamps = false;
}

