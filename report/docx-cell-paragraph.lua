-- Word requires every table cell to end with a paragraph. Quarto places each
-- captioned flextable inside a one-cell caption table, so that cell ends with
-- the raw OpenXML table and Word reports "unreadable content". This filter
-- appends an empty paragraph to any cell whose last block is a raw table.
-- Runs at post-render, after Quarto has built the caption tables.

local function ends_with_raw_table(blocks)
  local last = blocks[#blocks]
  while last and last.t == "Div" do
    last = last.content[#last.content]
  end
  return last ~= nil and last.t == "RawBlock" and last.format == "openxml"
    and last.text:find("</w:tbl>%s*$") ~= nil
end

local function fix_rows(rows)
  for i, row in ipairs(rows) do
    local cells = row.cells
    for j, cell in ipairs(cells) do
      if ends_with_raw_table(cell.contents) then
        local contents = cell.contents
        contents:insert(pandoc.RawBlock("openxml", "<w:p/>"))
        cell.contents = contents
        cells[j] = cell
      end
    end
    row.cells = cells
    rows[i] = row
  end
  return rows
end

function Table(tbl)
  if not FORMAT:match("docx") then
    return nil
  end
  local head = tbl.head
  head.rows = fix_rows(head.rows)
  tbl.head = head
  local bodies = tbl.bodies
  for k, body in ipairs(bodies) do
    body.head = fix_rows(body.head)
    body.body = fix_rows(body.body)
    bodies[k] = body
  end
  tbl.bodies = bodies
  local foot = tbl.foot
  foot.rows = fix_rows(foot.rows)
  tbl.foot = foot
  return tbl
end
