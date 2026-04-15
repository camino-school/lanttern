import React from "react";

import {
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  RowData,
  useReactTable,
} from "@tanstack/react-table";

import { Badge, Icon } from "../";

declare module "@tanstack/react-table" {
  interface TableMeta<TData extends RowData> {
    pushEvent?: (event: string, payload: object) => void;
    filterSubjectsActive?: boolean;
    filterYearsActive?: boolean;
  }
}

const openFilterModal = (id: string) => {
  const el = document.getElementById(id);
  if (el) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const liveSocket = (window as any).liveSocket;
    liveSocket?.execJS(el, el.getAttribute("data-show"));
  }
};

type Subject = {
  id: number;
  name: string;
};

type Year = {
  id: number;
  name: string;
};

type CurriculumItem = {
  id: number;
  name: string;
  code: string;
  subjects: Subject[];
  years: Year[];
};

const columnHelper = createColumnHelper<CurriculumItem>();

const columns = [
  columnHelper.accessor("id", {
    header: () => "Id",
    cell: (info) => <Badge>#{info.getValue()}</Badge>,
  }),
  columnHelper.accessor("code", {
    header: () => "Code",
    cell: (info) => {
      if (info.getValue()) {
        return <Badge>({info.getValue()})</Badge>;
      } else {
        return "—";
      }
    },
  }),
  columnHelper.accessor("name", {
    header: () => "Name",
  }),
  columnHelper.accessor("subjects", {
    header: ({ table }) => {
      const { filterSubjectsActive } = table.options.meta || {};
      return (
        <div className="flex items-center gap-2">
          Subjects
          <button
            type="button"
            className="hover:opacity-50"
            onClick={() => openFilterModal("subjects-filter-modal")}
          >
            <Icon
              name={filterSubjectsActive ? "hero-funnel-mini" : "hero-funnel"}
              className={
                filterSubjectsActive ? "text-ltrn-primary" : "text-ltrn-subtle"
              }
            />
          </button>
        </div>
      );
    },
    cell: (info) => (
      <div className="flex flex-wrap gap-2">
        {info.getValue().map((s) => (
          <Badge key={s.id}>{s.name}</Badge>
        ))}
      </div>
    ),
  }),
  columnHelper.accessor("years", {
    header: ({ table }) => {
      const { filterYearsActive } = table.options.meta || {};
      return (
        <div className="flex items-center gap-2">
          Years
          <button
            type="button"
            className="hover:opacity-50"
            onClick={() => openFilterModal("years-filter-modal")}
          >
            <Icon
              name={filterYearsActive ? "hero-funnel-mini" : "hero-funnel"}
              className={
                filterYearsActive ? "text-ltrn-primary" : "text-ltrn-subtle"
              }
            />
          </button>
        </div>
      );
    },
    cell: (info) => (
      <div className="flex flex-wrap gap-2">
        {info.getValue().map((s) => (
          <Badge key={s.id}>{s.name}</Badge>
        ))}
      </div>
    ),
  }),
  columnHelper.display({
    id: "actions", // Required because there is no accessorKey
    // header: '',
    cell: (info) => {
      const { pushEvent } = info.table.options.meta || {};
      const rowData = info.row.original;

      const handleEdit = () => {
        // Send the event back to your Phoenix LiveView
        pushEvent?.("edit_curriculum_item", { id: rowData.id });
      };

      return (
        <div className="flex gap-2">
          <button
            onClick={handleEdit}
            className="flex items-center justify-center size-9 rounded-full hover:bg-ltrn-light"
          >
            <Icon name="hero-pencil-mini" />
          </button>
        </div>
      );
    },
  }),
];

export function CurriculumTable({
  curriculumItems,
  pushEvent,
  filterSubjectsActive,
  filterYearsActive,
}: {
  curriculumItems: CurriculumItem[];
  pushEvent: () => void;
  filterSubjectsActive: boolean;
  filterYearsActive: boolean;
}) {
  const table = useReactTable({
    data: curriculumItems,
    columns,
    getCoreRowModel: getCoreRowModel(),
    meta: {
      pushEvent, // The function injected by live_react
      filterSubjectsActive,
      filterYearsActive,
    },
  });

  return (
    <div className="bg-white shadow-xl">
      <table>
        <thead>
          {table.getHeaderGroups().map((headerGroup) => (
            <tr key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <th
                  key={header.id}
                  className="sticky z-10 top-0 font-display font-bold text-sm bg-white"
                >
                  <div className="flex gap-2 p-4">
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext(),
                        )}
                  </div>
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody>
          {table.getRowModel().rows.map((row) => (
            <tr key={row.id} className="hover:bg-ltrn-lightest">
              {row.getVisibleCells().map((cell) => (
                <td key={cell.id} className="p-4">
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
