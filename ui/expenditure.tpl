{include file="sections/header.tpl"}
<style>
.summary-card {
    padding: 15px;
    border-radius: 4px;
    margin-bottom: 15px;
    text-align: center;
    color: #fff;
    height: 160px;
    display: flex;
    flex-direction: column;
    justify-content: center;
}
.summary-card .amount { font-size: 22px; font-weight: bold; }
.summary-card .label-text { font-size: 12px; opacity: 0.9; }
.card-income { background: #27ae60; }
.card-outcome { background: #e74c3c; }
.card-balance { background: #2980b9; }
.card-balance.negative { background: #c0392b; }
.card-tax { background: #8e44ad; }
.card-sub { font-size: 12px; background: rgba(255,255,255,0.15); border-radius: 3px; padding: 4px 8px; margin-top: 5px; }
.card-sub .amount { font-size: 14px; }
.filter-row { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.filter-row select, .filter-row .input-group { margin-bottom: 0; }
.filter-row .input-group { width: auto; min-width: 200px; flex: 1 1 200px; }
.chart-box { position: relative; height: 260px; }
@media (max-width: 767px) {
    .chart-box { height: 200px; }
    .summary-card { height: auto; padding: 10px; }
    .summary-card .amount { font-size: 18px; }
}
</style>

<div class="row">
    <div class="col-sm-6 col-md-3">
        <div class="summary-card card-income">
            <div class="label-text">{Lang::T('Total Income')}</div>
            <div class="amount">{Lang::moneyFormat($totalIncome)}</div>
            <div class="card-sub">
                <div>{Lang::T('Transactions')}: <span class="amount">{Lang::moneyFormat($transactionIncome)}</span></div>
                <div>{Lang::T('Manual')}: <span class="amount">{Lang::moneyFormat($manualIncome)}</span></div>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-md-3">
        <div class="summary-card card-tax">
            <div class="label-text">{Lang::T('Tax')} ({$taxRate}%)</div>
            <div class="amount">{Lang::moneyFormat($taxAmount)}</div>
            <div class="card-sub">
                {Lang::T('Net after tax')}: <span class="amount">{Lang::moneyFormat($netAfterTax)}</span>
            </div>
        </div>
    </div>
    <div class="col-sm-6 col-md-3">
        <div class="summary-card card-outcome">
            <div class="label-text">{Lang::T('Total Expenditure')}</div>
            <div class="amount">{Lang::moneyFormat($totalOutcome)}</div>
        </div>
    </div>
    <div class="col-sm-6 col-md-3">
        <div class="summary-card card-balance {if $netBalance < 0}negative{/if}">
            <div class="label-text">{Lang::T('Net Balance')}</div>
            <div class="amount">{Lang::moneyFormat($netBalance)}</div>
            <div class="card-sub">{Lang::T('Income')} - {Lang::T('Tax')} - {Lang::T('Expense')}</div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <div class="btn-group pull-right">
                    <a class="btn btn-success btn-xs" href="{$_url}plugin/expenditure_add&type=income"><span class="glyphicon glyphicon-plus" aria-hidden="true"></span> {Lang::T('Add Income')}</a>
                    <a class="btn btn-danger btn-xs" href="{$_url}plugin/expenditure_add&type=outcome"><span class="glyphicon glyphicon-plus" aria-hidden="true"></span> {Lang::T('Add Expenditure')}</a>
                </div>
                Finance
            </div>
            <div class="panel-body">
                <div class="filter-row">
                    <select class="form-control" id="fPeriod" style="width:auto;min-width:100px">
                        <option value="monthly" {if $period eq 'monthly'}selected{/if}>Monthly</option>
                        <option value="yearly" {if $period eq 'yearly'}selected{/if}>Yearly</option>
                    </select>
                    {if $period eq 'yearly'}
                    <select class="form-control" id="fYear" style="width:auto;min-width:90px">
                        {foreach $yearRange as $y}<option value="{$y}" {if $year eq $y}selected{/if}>{$y}</option>{/foreach}
                    </select>
                    {else}
                    <select class="form-control" id="fMonth" style="width:auto;min-width:120px">
                        {foreach $monthNames as $i => $m}<option value="{$i+1}" {if $month eq ($i+1)}selected{/if}>{$m}</option>{/foreach}
                    </select>
                    <select class="form-control" id="fYear" style="width:auto;min-width:90px">
                        {foreach $yearRange as $y}<option value="{$y}" {if $year eq $y}selected{/if}>{$y}</option>{/foreach}
                    </select>
                    {/if}
                    <div class="input-group">
                        <input type="text" class="form-control" id="fSearch" value="{$search}" placeholder="Search description, category, notes">
                        <span class="input-group-btn"><button class="btn btn-success" id="btnSearch">Search</button></span>
                    </div>
                </div>

                <div class="row" style="margin-top:15px">
                    <div class="col-md-6">
                        <div class="chart-box"><canvas id="financeChart"></canvas></div>
                    </div>
                    <div class="col-md-6">
                        <div class="chart-box"><canvas id="netChart"></canvas></div>
                    </div>
                </div>

                <hr style="margin-top:15px;margin-bottom:10px">

                <ul class="nav nav-tabs">
                    <li class="active"><a data-toggle="tab" href="#transTab">{Lang::T('Transactions')} ({$transactions|@count})</a></li>
                    <li><a data-toggle="tab" href="#incomeTab">{Lang::T('Manual Income')} ({$incomes|@count})</a></li>
                    <li><a data-toggle="tab" href="#outcomeTab">{Lang::T('Expenditure')} ({$outcomes|@count})</a></li>
                </ul>
                <div class="tab-content">
                    <div id="transTab" class="tab-pane fade in active">
                        <div class="table-responsive" style="margin-top:10px">
                            <table class="table table-bordered table-striped table-condensed">
                                <thead><tr>
                                    <th>{Lang::T('Date')}</th><th>{Lang::T('Invoice')}</th><th>{Lang::T('Username')}</th><th>{Lang::T('Plan')}</th>
                                    <th class="text-right">{Lang::T('Amount')}</th><th>{Lang::T('Method')}</th><th>{Lang::T('Type')}</th>
                                </tr></thead>
                                <tbody>
                                {foreach $transactions as $r}
                                <tr>
                                    <td>{Lang::dateFormat($r['recharged_on'])}</td>
                                    <td>{$r['invoice']}</td>
                                    <td>{$r['username']}</td>
                                    <td>{$r['plan_name']}</td>
                                    <td class="text-right text-success">{Lang::moneyFormat($r['price'])}</td>
                                    <td>{$r['method']}</td>
                                    <td>{$r['type']}</td>
                                </tr>
                                {foreachelse}
                                <tr><td colspan="7" class="text-center">{Lang::T('No transactions in this period')}</td></tr>
                                {/foreach}
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div id="incomeTab" class="tab-pane fade">
                        <div class="table-responsive" style="margin-top:10px">
                            <table class="table table-bordered table-striped table-condensed">
                                <thead><tr>
                                    <th>{Lang::T('Date')}</th><th>{Lang::T('Description')}</th><th>{Lang::T('Category')}</th>
                                    <th class="text-right">{Lang::T('Amount')}</th><th>{Lang::T('Notes')}</th>
                                    <th class="text-center">{Lang::T('Manage')}</th>
                                </tr></thead>
                                <tbody>
                                {foreach $incomes as $r}
                                <tr>
                                    <td>{Lang::dateFormat($r['income_date'])}</td>
                                    <td>{$r['description']}</td>
                                    <td>{$r['category']}</td>
                                    <td class="text-right text-success">{Lang::moneyFormat($r['amount'])}</td>
                                    <td>{$r['notes']|truncate:50}</td>
                                    <td class="text-center">
                                        <a href="{$_url}plugin/expenditure_edit&type=income&id={$r['id']}" class="btn btn-info btn-xs">{Lang::T('Edit')}</a>
                                        <a href="{$_url}plugin/expenditure_delete&type=income&id={$r['id']}" class="btn btn-danger btn-xs" onclick="return confirm('Delete this income?')">{Lang::T('Delete')}</a>
                                    </td>
                                </tr>
                                {foreachelse}
                                <tr><td colspan="6" class="text-center">{Lang::T('No manual income records')}</td></tr>
                                {/foreach}
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div id="outcomeTab" class="tab-pane fade">
                        <div class="table-responsive" style="margin-top:10px">
                            <table class="table table-bordered table-striped table-condensed">
                                <thead><tr>
                                    <th>{Lang::T('Date')}</th><th>{Lang::T('Description')}</th><th>{Lang::T('Category')}</th>
                                    <th class="text-right">{Lang::T('Amount')}</th><th>{Lang::T('Notes')}</th>
                                    <th class="text-center">{Lang::T('Manage')}</th>
                                </tr></thead>
                                <tbody>
                                {foreach $outcomes as $r}
                                <tr>
                                    <td>{Lang::dateFormat($r['expense_date'])}</td>
                                    <td>{$r['description']}</td>
                                    <td>{$r['category']}</td>
                                    <td class="text-right text-danger">{Lang::moneyFormat($r['amount'])}</td>
                                    <td>{$r['notes']|truncate:50}</td>
                                    <td class="text-center">
                                        <a href="{$_url}plugin/expenditure_edit&type=outcome&id={$r['id']}" class="btn btn-info btn-xs">{Lang::T('Edit')}</a>
                                        <a href="{$_url}plugin/expenditure_delete&type=outcome&id={$r['id']}" class="btn btn-danger btn-xs" onclick="return confirm('Delete this expenditure?')">{Lang::T('Delete')}</a>
                                    </td>
                                </tr>
                                {foreachelse}
                                <tr><td colspan="6" class="text-center">{Lang::T('No expenditure records')}</td></tr>
                                {/foreach}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

{include file="sections/footer.tpl"}
<script id="financeScript">
var chartMonths = {$chartMonths};
var chartIncome = {$chartIncome};
var chartOutcome = {$chartOutcome};
var chartNetBalance = {$chartNetBalance};
var baseUrl = '{$_url}';
var curMonth = '{$month}';
</script>
{literal}<script>
(function() {
var cm = chartMonths, ci = chartIncome, co = chartOutcome, cn = chartNetBalance;
var isMobile = window.innerWidth < 768;
var tickSize = isMobile ? 8 : 11;
var legSize = isMobile ? 9 : 12;
var chartOpts = {
    responsive: true, maintainAspectRatio: false,
    plugins: {
        legend: {labels: {font: {size: legSize}}, position: 'top'}
    },
    scales: {
        x: {ticks: {font: {size: tickSize}}},
        y: {ticks: {font: {size: tickSize}}, beginAtZero: true}
    }
};
document.addEventListener('DOMContentLoaded', function() {
    var el = document.getElementById('financeChart');
    if (el) {
        new Chart(el.getContext('2d'), {
            type: 'bar',
            data: {
                labels: cm,
                datasets: [
                    {label: 'Income', data: ci, backgroundColor: 'rgba(39,174,96,0.7)', borderColor: '#27ae60', borderWidth: 1},
                    {label: 'Expenditure', data: co, backgroundColor: 'rgba(231,76,60,0.7)', borderColor: '#e74c3c', borderWidth: 1}
                ]
            },
            options: chartOpts
        });
    }

    var nel = document.getElementById('netChart');
    if (nel) {
        new Chart(nel.getContext('2d'), {
            type: 'line',
            data: {
                labels: cm,
                datasets: [{
                    label: 'Net Balance',
                    data: cn,
                    borderColor: '#2980b9',
                    backgroundColor: 'rgba(41,128,185,0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.3,
                    pointRadius: isMobile ? 2 : 4,
                    pointBackgroundColor: '#2980b9'
                }]
            },
            options: chartOpts
        });
    }

    function goFilter() {
        var period = document.getElementById('fPeriod').value;
        var year = document.getElementById('fYear').value;
        var search = document.getElementById('fSearch').value;
        var url = baseUrl + 'plugin/expenditure&period=' + period + '&year=' + year;
        var fm = document.getElementById('fMonth');
        url += '&month=' + (fm ? fm.value : curMonth);
        if (search) url += '&search=' + encodeURIComponent(search);
        window.location.href = url;
    }

    document.getElementById('fPeriod').addEventListener('change', goFilter);
    document.getElementById('fYear').addEventListener('change', goFilter);
    var fm = document.getElementById('fMonth');
    if (fm) fm.addEventListener('change', goFilter);
    document.getElementById('btnSearch').addEventListener('click', goFilter);
    document.getElementById('fSearch').addEventListener('keydown', function(e) {
        if (e.key === 'Enter') goFilter();
    });
});
})();
</script>{/literal}
