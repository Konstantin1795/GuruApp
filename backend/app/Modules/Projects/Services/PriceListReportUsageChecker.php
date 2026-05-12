<?php

namespace App\Modules\Projects\Services;

/**
 * Проверка использования прайс-листа / позиции / группы в отчётах (REPORT).
 *
 * Временное поведение (до REPORT): методы всегда возвращают false.
 * Пока отчёты не существуют, позиции не могут быть зафиксированы в REPORT, поэтому
 * hard-delete прайса/позиции допустим и не ломает историчность «как в отчёте».
 *
 * TODO(REPORT): после появления операции REPORT и таблиц снимков/строк отчёта обязательно
 * доработать этот класс, иначе {@see PriceListDeletionService} будет ошибочно делать
 * hard-delete сущностей, уже участвовавших в отчётах (нарушение историчности ТЗ-10B).
 * Проверять минимум:
 * - ссылки по `price_list_id`;
 * - ссылки по `price_list_group_id` (если в модели отчёта есть отдельная FK);
 * - ссылки по `price_list_position_id`;
 * - строки snapshot / report items (включая зафиксированные копии наименований/цен), если ID не хранятся напрямую.
 */
final class PriceListReportUsageChecker
{
    public function priceListUsedInReports(int $priceListId): bool
    {
        return false;
    }

    public function priceListPositionUsedInReports(int $positionId): bool
    {
        return false;
    }
}
