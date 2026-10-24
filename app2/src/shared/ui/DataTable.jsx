import { useState } from 'react';
import { flexRender, getCoreRowModel, getSortedRowModel, useReactTable } from '@tanstack/react-table';
import { ArrowDown, ArrowUp, ArrowUpDown } from 'lucide-react';
import { Skeleton } from './Skeletons';
import { cn } from '../lib/cn';

export function DataTable({ columns, data, isPending, skeletonRows = 8, onRowClick, empty, rowClassName, getRowId }) {
  const [sorting, setSorting] = useState([]);
  const table = useReactTable({
    data: data ?? [],
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    defaultColumn: { enableSorting: false },
    getRowId,
  });
  const leaf = table.getAllLeafColumns();
  const rows = table.getRowModel().rows;

  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-left text-sm">
        <thead>
          {table.getHeaderGroups().map((hg) => (
            <tr key={hg.id} className="border-b border-line text-xs text-ink-2">
              {hg.headers.map((h) => {
                const dir = h.column.getIsSorted();
                const label = flexRender(h.column.columnDef.header, h.getContext());
                return (
                  <th
                    key={h.id}
                    scope="col"
                    aria-sort={dir === 'asc' ? 'ascending' : dir === 'desc' ? 'descending' : undefined}
                    className="whitespace-nowrap px-4 py-2.5 font-medium"
                  >
                    {h.column.getCanSort() ? (
                      <button type="button" onClick={h.column.getToggleSortingHandler()} className="inline-flex items-center gap-1 font-medium">
                        {label}
                        {dir === 'asc' ? <ArrowUp className="size-3" /> : dir === 'desc' ? <ArrowDown className="size-3" /> : <ArrowUpDown className="size-3 text-ink-3" />}
                      </button>
                    ) : label}
                  </th>
                );
              })}
            </tr>
          ))}
        </thead>
        <tbody>
          {isPending
            ? Array.from({ length: skeletonRows }).map((_, i) => (
                <tr key={i} className="h-14 border-b border-line">
                  {leaf.map((c) => <td key={c.id} className="px-4"><Skeleton className="h-4 w-3/4" /></td>)}
                </tr>
              ))
            : rows.length === 0
              ? <tr><td colSpan={leaf.length}>{empty}</td></tr>
              : rows.map((row) => (
                  <tr
                    key={row.id}
                    tabIndex={onRowClick ? 0 : undefined}
                    onClick={onRowClick ? () => onRowClick(row.original) : undefined}
                    onKeyDown={onRowClick ? (e) => e.key === 'Enter' && onRowClick(row.original) : undefined}
                    className={cn('border-b border-line', onRowClick && 'cursor-pointer hover:bg-muted', rowClassName?.(row.original))}
                  >
                    {row.getVisibleCells().map((cell) => (
                      <td key={cell.id} className="px-4 py-3 align-middle">{flexRender(cell.column.columnDef.cell, cell.getContext())}</td>
                    ))}
                  </tr>
                ))}
        </tbody>
      </table>
    </div>
  );
}
