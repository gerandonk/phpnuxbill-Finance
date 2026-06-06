{include file="sections/header.tpl"}
{if $type eq 'income'}{assign var="label" value="Income"}{assign var="dateVal" value=$rec['income_date']}{else}{assign var="label" value="Expenditure"}{assign var="dateVal" value=$rec['expense_date']}{/if}
<div class="row">
    <div class="col-sm-6 col-sm-offset-3">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">Edit {$label}</div>
            <div class="panel-body">
                <form method="post" action="{$_url}plugin/expenditure_update">
                    <input type="hidden" name="id" value="{$rec['id']}">
                    <input type="hidden" name="type" value="{$type}">
                    <div class="form-group">
                        <label>Description</label>
                        <input type="text" class="form-control" name="description" value="{$rec['description']}" required>
                    </div>
                    <div class="form-group">
                        <label>Amount</label>
                        <input type="number" class="form-control" name="amount" step="0.01" min="0.01" value="{$rec['amount']}" required>
                    </div>
                    <div class="form-group">
                        <label>Category</label>
                        <input type="text" class="form-control" name="category" value="{$rec['category']}" placeholder="e.g. Operational, Maintenance, etc.">
                    </div>
                    <div class="form-group">
                        <label>Date</label>
                        <input type="date" class="form-control" name="date" value="{$dateVal}" required>
                    </div>
                    <div class="form-group">
                        <label>Notes</label>
                        <textarea class="form-control" name="notes" rows="3">{$rec['notes']}</textarea>
                    </div>
                    <div class="form-group text-right">
                        <a href="{$_url}plugin/expenditure" class="btn btn-default">Cancel</a>
                        <button type="submit" class="btn btn-primary">Update</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
{include file="sections/footer.tpl"}
