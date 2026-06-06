{include file="sections/header.tpl"}
{if $type eq 'income'}{assign var="label" value="{Lang::T('Income')}"}{else}{assign var="label" value="{Lang::T('Expenditure')}"}{/if}
<div class="row">
    <div class="col-sm-6 col-sm-offset-3">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">{Lang::T('Add')} {$label}</div>
            <div class="panel-body">
                <form method="post" action="{$_url}plugin/expenditure_post">
                    <input type="hidden" name="type" value="{$type}">
                    <div class="form-group">
                        <label>{Lang::T('Description')}</label>
                        <input type="text" class="form-control" name="description" required>
                    </div>
                    <div class="form-group">
                        <label>{Lang::T('Amount')}</label>
                        <input type="number" class="form-control" name="amount" step="0.01" min="0.01" required>
                    </div>
                    <div class="form-group">
                        <label>{Lang::T('Category')}</label>
                        <input type="text" class="form-control" name="category" placeholder="e.g. Operational, Maintenance, etc.">
                    </div>
                    <div class="form-group">
                        <label>{Lang::T('Date')}</label>
                        <input type="date" class="form-control" name="date" value="{$smarty.now|date_format:'Y-m-d'}" required>
                    </div>
                    <div class="form-group">
                        <label>{Lang::T('Notes')}</label>
                        <textarea class="form-control" name="notes" rows="3"></textarea>
                    </div>
                    <div class="form-group text-right">
                        <a href="{$_url}plugin/expenditure" class="btn btn-default">{Lang::T('Cancel')}</a>
                        <button type="submit" class="btn btn-primary">{Lang::T('Save')}</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
{include file="sections/footer.tpl"}
