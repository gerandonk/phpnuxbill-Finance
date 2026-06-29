<?php

/**
 * 
 * PHP Mikrotik Billing (https://github.com/hotspotbilling/phpnuxbill/)
 *
 * Finance Plugin for PHP Mikrotik Billing
 *
 * @author: Gerandonk Mods <noc@igrwifi.my.id>
 * Website: https://igrwifi.my.id/
 * GitHub: https://github.com/gerandonk/
 * Telegram: https://t.me/sklitinov/
 *
 **/

register_menu("Finance", true, "expenditure", 'AFTER_SETTINGS', 'glyphicon glyphicon-shopping-cart', '', '', ['Admin', 'SuperAdmin']);

function expenditure_create_tables()
{
    $t1 = ORM::for_table('tbl_incomes')->raw_query("SHOW TABLES LIKE 'tbl_incomes'")->find_one();
    if (!$t1) {
        ORM::raw_execute("
            CREATE TABLE `tbl_incomes` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `description` VARCHAR(255) NOT NULL,
                `amount` DECIMAL(15,2) NOT NULL,
                `category` VARCHAR(100) DEFAULT NULL,
                `income_date` DATE NOT NULL,
                `notes` TEXT DEFAULT NULL,
                `created_by` INT(11) DEFAULT NULL,
                `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
    $t2 = ORM::for_table('tbl_expenditures')->raw_query("SHOW TABLES LIKE 'tbl_expenditures'")->find_one();
    if (!$t2) {
        ORM::raw_execute("
            CREATE TABLE `tbl_expenditures` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `description` VARCHAR(255) NOT NULL,
                `amount` DECIMAL(15,2) NOT NULL,
                `category` VARCHAR(100) DEFAULT NULL,
                `expense_date` DATE NOT NULL,
                `notes` TEXT DEFAULT NULL,
                `created_by` INT(11) DEFAULT NULL,
                `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    }
}

function expenditure_get_tax_rate()
{
    global $config;
    if (!isset($config['enable_tax']) || $config['enable_tax'] != 'yes') {
        return 0;
    }
    $taxRateSetting = $config['tax_rate'] ?? null;
    if ($taxRateSetting === 'custom') {
        return (float)($config['custom_tax_rate'] ?? 0);
    }
    return (float)($taxRateSetting ?? 0);
}

function expenditure()
{
    global $ui, $config;
    _admin();
    expenditure_create_tables();

    $period = _get('period', 'monthly');
    $month = (int)_get('month', date('m'));
    $year = (int)_get('year', date('Y'));
    $search = _get('search');

    if ($period == 'yearly') {
        $dateFrom = "$year-01-01";
        $dateTo = "$year-12-31";
    } else {
        $dateFrom = "$year-$month-01";
        $dateTo = date('Y-m-t', strtotime($dateFrom));
    }

    $transactionIncome = (float)ORM::for_table('tbl_transactions')
        ->where_raw("recharged_on BETWEEN ? AND ?", [$dateFrom, $dateTo])
        ->sum('price');

    $manualIncome = (float)ORM::for_table('tbl_incomes')
        ->where_raw("income_date BETWEEN ? AND ?", [$dateFrom, $dateTo])
        ->sum('amount');

    $totalOutcome = (float)ORM::for_table('tbl_expenditures')
        ->where_raw("expense_date BETWEEN ? AND ?", [$dateFrom, $dateTo])
        ->sum('amount');

    $taxRate = expenditure_get_tax_rate();
    $taxAmount = $transactionIncome * ($taxRate / 100);
    $totalIncome = $transactionIncome + $manualIncome;

    $netBalance = $totalIncome - $taxAmount - $totalOutcome;
    $netAfterTax = ($totalIncome - $taxAmount);

    $qIncome = ORM::for_table('tbl_incomes')
        ->where_raw("income_date BETWEEN ? AND ?", [$dateFrom, $dateTo]);
    $qOutcome = ORM::for_table('tbl_expenditures')
        ->where_raw("expense_date BETWEEN ? AND ?", [$dateFrom, $dateTo]);

    $qTransactions = ORM::for_table('tbl_transactions')
        ->where_raw("recharged_on BETWEEN ? AND ?", [$dateFrom, $dateTo]);

    if (!empty($search)) {
        $qIncome->where_raw("(description LIKE ? OR category LIKE ? OR notes LIKE ?)", ["%$search%", "%$search%", "%$search%"]);
        $qOutcome->where_raw("(description LIKE ? OR category LIKE ? OR notes LIKE ?)", ["%$search%", "%$search%", "%$search%"]);
        $qTransactions->where_raw("(plan_name LIKE ? OR username LIKE ? OR method LIKE ? OR note LIKE ?)", ["%$search%", "%$search%", "%$search%", "%$search%"]);
    }

    $incomes = $qIncome->order_by_desc('income_date')->find_array();
    $outcomes = $qOutcome->order_by_desc('expense_date')->find_array();
    $transactions = $qTransactions->order_by_desc('recharged_on')->find_array();

    $chartMonths = [];
    $chartIncome = [];
    $chartOutcome = [];
    for ($m = 1; $m <= 12; $m++) {
        $from = "$year-" . str_pad($m, 2, '0', STR_PAD_LEFT) . "-01";
        $to = date('Y-m-t', strtotime($from));
        $chartMonths[] = date('M', strtotime($from));
        $chartIncome[] = (float)ORM::for_table('tbl_transactions')
            ->where_raw("recharged_on BETWEEN ? AND ?", [$from, $to])->sum('price');
        $chartOutcome[] = (float)ORM::for_table('tbl_expenditures')
            ->where_raw("expense_date BETWEEN ? AND ?", [$from, $to])->sum('amount');
    }

    $yearRange = range(date('Y') - 5, date('Y') + 1);
    $monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    $ui->assign('_title', 'Finance');
    $ui->assign('_system_menu', 'plugin/expenditure');
    $admin = Admin::_info();
    $ui->assign('_admin', $admin);
    $ui->assign('incomes', $incomes);
    $ui->assign('outcomes', $outcomes);
    $ui->assign('transactions', $transactions);
    $ui->assign('transactionIncome', $transactionIncome);
    $ui->assign('manualIncome', $manualIncome);
    $ui->assign('totalIncome', $totalIncome);
    $ui->assign('totalOutcome', $totalOutcome);
    $ui->assign('taxRate', $taxRate);
    $ui->assign('taxAmount', $taxAmount);
    $ui->assign('netAfterTax', $netAfterTax);
    $ui->assign('netBalance', $netBalance);
    $chartNetBalance = [];
    for ($m = 0; $m < 12; $m++) {
        $chartNetBalance[] = $chartIncome[$m] - $chartOutcome[$m];
    }

    $ui->assign('chartMonths', json_encode($chartMonths));
    $ui->assign('chartIncome', json_encode($chartIncome));
    $ui->assign('chartOutcome', json_encode($chartOutcome));
    $ui->assign('chartNetBalance', json_encode($chartNetBalance));
    $ui->assign('period', $period);
    $ui->assign('month', $month);
    $ui->assign('year', $year);
    $ui->assign('yearRange', $yearRange);
    $ui->assign('monthNames', $monthNames);
    $ui->assign('search', $search);
    $ui->display('expenditure.tpl');
}

function expenditure_add()
{
    global $ui;
    _admin();
    $type = _get('type', 'outcome');
    $label = $type == 'income' ? 'Income' : 'Expenditure';

    $ui->assign('_title', "Add $label");
    $ui->assign('_system_menu', 'plugin/expenditure');
    $admin = Admin::_info();
    $ui->assign('_admin', $admin);
    $ui->assign('type', $type);
    $ui->display('expenditure_add.tpl');
}

function expenditure_post()
{
    _admin();

    $type = _post('type', 'outcome');
    $description = _post('description');
    $amount = (float)_post('amount');
    $category = _post('category');
    $date = _post('date');
    $notes = _post('notes');

    if (empty($description) || $amount <= 0 || empty($date)) {
        r2(U . "plugin/expenditure_add&type=$type", 'e', 'Description, amount, and date are required');
    }

    $table = $type == 'income' ? 'tbl_incomes' : 'tbl_expenditures';
    $dateCol = $type == 'income' ? 'income_date' : 'expense_date';

    $d = ORM::for_table($table)->create();
    $d->description = $description;
    $d->amount = $amount;
    $d->category = $category;
    $d->$dateCol = $date;
    $d->notes = $notes;
    $d->created_by = Admin::getID();
    $d->save();

    $label = $type == 'income' ? 'Income' : 'Expenditure';
    r2(U . 'plugin/expenditure', 's', "$label added successfully");
}

function expenditure_edit()
{
    global $ui;
    _admin();

    $type = _get('type', 'outcome');
    $id = (int)_get('id');
    $table = $type == 'income' ? 'tbl_incomes' : 'tbl_expenditures';
    $label = $type == 'income' ? 'Income' : 'Expenditure';

    $rec = ORM::for_table($table)->find_one($id);
    if (!$rec) {
        r2(U . 'plugin/expenditure', 'e', "$label not found");
    }

    $ui->assign('_title', "Edit $label");
    $ui->assign('_system_menu', 'plugin/expenditure');
    $admin = Admin::_info();
    $ui->assign('_admin', $admin);
    $ui->assign('rec', $rec);
    $ui->assign('type', $type);
    $ui->display('expenditure_edit.tpl');
}

function expenditure_update()
{
    _admin();

    $type = _post('type', 'outcome');
    $id = (int)_post('id');
    $table = $type == 'income' ? 'tbl_incomes' : 'tbl_expenditures';
    $dateCol = $type == 'income' ? 'income_date' : 'expense_date';
    $label = $type == 'income' ? 'Income' : 'Expenditure';

    $rec = ORM::for_table($table)->find_one($id);
    if (!$rec) {
        r2(U . 'plugin/expenditure', 'e', "$label not found");
    }

    $description = _post('description');
    $amount = (float)_post('amount');
    $category = _post('category');
    $date = _post('date');
    $notes = _post('notes');

    if (empty($description) || $amount <= 0 || empty($date)) {
        r2(U . "plugin/expenditure_edit&type=$type&id=$id", 'e', 'Description, amount, and date are required');
    }

    $rec->description = $description;
    $rec->amount = $amount;
    $rec->category = $category;
    $rec->$dateCol = $date;
    $rec->notes = $notes;
    $rec->save();

    r2(U . 'plugin/expenditure', 's', "$label updated successfully");
}

function expenditure_delete()
{
    _admin();

    $type = _get('type', 'outcome');
    $id = (int)_get('id');
    $table = $type == 'income' ? 'tbl_incomes' : 'tbl_expenditures';
    $label = $type == 'income' ? 'Income' : 'Expenditure';

    $rec = ORM::for_table($table)->find_one($id);
    if ($rec) {
        $rec->delete();
        r2(U . 'plugin/expenditure', 's', "$label deleted successfully");
    } else {
        r2(U . 'plugin/expenditure', 'e', "$label not found");
    }
}
