<?php

namespace App\Providers;

use App\Modules\Companies\Models\Company;
use App\Modules\Projects\Models\Project;
use App\Policies\CompanyPolicy;
use App\Policies\ProjectPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

final class AuthServiceProvider extends ServiceProvider
{
    /**
     * @var array<class-string, class-string>
     */
    protected $policies = [
        Company::class => CompanyPolicy::class,
        Project::class => ProjectPolicy::class,
    ];
}

