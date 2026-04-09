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
              className={filterSubjectsActive ? "text-ltrn-primary" : "text-ltrn-subtle"}
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
              className={filterYearsActive ? "text-ltrn-primary" : "text-ltrn-subtle"}
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

// <.icon_button
//   type="button"
//   sr_text={gettext("Edit curriculum item")}
//   name="hero-pencil-mini"
//   size="sm"
//   theme="ghost"
//   phx-click={
//     JS.patch(
//       ~p"/curriculum/component/#{@curriculum_component}?is_editing_curriculum_item=#{curriculum_item.id}"
//     )
//   }
// />

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

// type Person = {
//   firstName: string;
//   lastName: string;
//   age: number;
//   visits: number;
//   status: string;
//   progress: number;
// };

// const defaultData: Person[] = [
//   {
//     firstName: "tanner",
//     lastName: "linsley",
//     age: 24,
//     visits: 100,
//     status: "In Relationship",
//     progress: 50,
//   },
//   {
//     firstName: "tandy",
//     lastName: "miller",
//     age: 40,
//     visits: 40,
//     status: "Single",
//     progress: 80,
//   },
//   {
//     firstName: "joe",
//     lastName: "dirte",
//     age: 45,
//     visits: 20,
//     status: "Complicated",
//     progress: 10,
//   },
// ];

// const columnHelper = createColumnHelper<Person>();

// const columns = [
//   columnHelper.accessor("firstName", {
//     cell: (info) => info.getValue(),
//     footer: (info) => info.column.id,
//   }),
//   columnHelper.accessor((row) => row.lastName, {
//     id: "lastName",
//     cell: (info) => <i>{info.getValue()}</i>,
//     header: () => <span>Last Name</span>,
//     footer: (info) => info.column.id,
//   }),
//   columnHelper.accessor("age", {
//     header: () => "Age",
//     cell: (info) => info.renderValue(),
//     footer: (info) => info.column.id,
//   }),
//   columnHelper.accessor("visits", {
//     header: () => <span>Visits</span>,
//     footer: (info) => info.column.id,
//   }),
//   columnHelper.accessor("status", {
//     header: "Status",
//     footer: (info) => info.column.id,
//   }),
//   columnHelper.accessor("progress", {
//     header: "Profile Progress",
//     footer: (info) => info.column.id,
//   }),
// ];

// export function CurriculumTable() {
//   const [data, _setData] = React.useState(() => [...defaultData]);
//   const rerender = React.useReducer(() => ({}), {})[1];

//   const table = useReactTable({
//     data,
//     columns,
//     getCoreRowModel: getCoreRowModel(),
//   });

//   return (
//     <div className="p-2">
//       <table>
//         <thead>
//           {table.getHeaderGroups().map((headerGroup) => (
//             <tr key={headerGroup.id}>
//               {headerGroup.headers.map((header) => (
//                 <th key={header.id}>
//                   {header.isPlaceholder
//                     ? null
//                     : flexRender(
//                         header.column.columnDef.header,
//                         header.getContext(),
//                       )}
//                 </th>
//               ))}
//             </tr>
//           ))}
//         </thead>
//         <tbody>
//           {table.getRowModel().rows.map((row) => (
//             <tr key={row.id}>
//               {row.getVisibleCells().map((cell) => (
//                 <td key={cell.id}>
//                   {flexRender(cell.column.columnDef.cell, cell.getContext())}
//                 </td>
//               ))}
//             </tr>
//           ))}
//         </tbody>
//         <tfoot>
//           {table.getFooterGroups().map((footerGroup) => (
//             <tr key={footerGroup.id}>
//               {footerGroup.headers.map((header) => (
//                 <th key={header.id}>
//                   {header.isPlaceholder
//                     ? null
//                     : flexRender(
//                         header.column.columnDef.footer,
//                         header.getContext(),
//                       )}
//                 </th>
//               ))}
//             </tr>
//           ))}
//         </tfoot>
//       </table>
//       <div className="h-4" />
//       <button onClick={() => rerender()} className="border p-2">
//         Rerender
//       </button>
//     </div>
//   );
// }
