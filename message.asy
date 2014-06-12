/**********************************************************
 * 由原来的message.mp移植过来.
 * 作者: qiupingwu@gmail.com  版本: 0.1
 * 日期: 2014-05-15
 **********************************************************/

/**********************************************************
 * TODO: 
 * 1. 当跨列消息的长度超时这两列间宽度时, 自动调整列宽度
 *      1        2        3
 *      |        |        |
 *  < a very long message for 2 >
 *      |        |        |
 * 2. 支持跨列的事件, 以表明这是一个同步事件;
 * 3. 支持预留跨列区块, 以支持自定义内容
 *      1        2        3
 *      |        |        |
 *  +------------------+  |
 *  | user define area |  |
 *  +------------------+  |
 *      |        |        |
 */

import settings;
outformat="pdf";

void showbox(string name);

int min_int(int a, int b)
{
    if (a < b)
    {
        return a;
    }
    return b;
}

real min_real(real a, real b)
{
    if (a < b)
    {
        return a;
    }
    return b;
}

int max_int(int a, int b)
{
    if (a > b)
    {
        return a;
    }
    return b;
}

real max_real(real a, real b)
{
    if (a > b)
    {
        return a;
    }
    return b;
}

struct message_t
{
    bool                seq;
    // 0: block, 1, non arrow, 2: arrow, 3: double arrow
    int                 type;
    int                 src;
    int                 dst;
    pen                 linecolor;
    string              text;
    pen                 textcolor;

    void operator init(bool seq=true,
                       int type=2,
                       int src,
                       int dst,
                       pen linecolor=black,
                       string text="",
                       pen textcolor=black)
    {
        this.seq = seq;
        this.type = type;
        this.src = src;
        this.dst = dst;
        this.linecolor = linecolor;
        this.text = text;
        this.textcolor = textcolor;
    }
}

struct oneline_message_t
{
    bool                seq;
    int                 type;
    int                 who;
    pen                 linecolor=black;
    string              text;
    pen                 textcolor=black;

    void operator init(bool seq=true, int type=0,
                       int who, pen linecolor=black,
                       string text, pen textcolor=black)
    {
        this.who = who;
        this.linecolor = linecolor;
        this.text = text;
        this.textcolor = textcolor;
    }
}

struct object_t
{
    string              name;
    real[]              yoffset;

    void operator init(string name, real[] yoffset)
    {
        this.name = name;
        this.yoffset = yoffset;
    }
}

object_t[] objects;
message_t[] messages;

real get_maxseqwidth()
{
    string              txt = '(XXX) ';
    path                pth;
    frame               frm;

    pth = box(frm, txt);
    return (max(pth).x - min(pth).x);
}

real get_rowspacing()
{
    string              txt = 'WUQIUPING13579';
    path                pth;
    frame               frm;

    pth = box(frm, txt);
    //write('get_rowspacing', (max(pth).y - min(pth).y) * 1.23);
    return (max(pth).y - min(pth).y) * 1.23;
}

int get_objects_count(message_t[] messages)
{
    int                 objects_count = 0;
    int                 i;

    for (i = 0; i < messages.length; ++i)
    {
        if (messages[i].src > objects_count)
        {
            objects_count = messages[i].src;
        }
        else if (messages[i].dst > objects_count)
        {
            objects_count = messages[i].dst;
        }
    }

    if (objects_count < objects.length)
    {
        objects_count = objects.length;
    }

    for (i = objects.length; i < objects_count; ++i)
    {
        showbox("UNKNOWN");
    }
    return objects_count;
}

real get_text_width(string text)
{
    frame               frm;
    path                pth;

    pth = box(frm, text);
    return max(pth).x - min(pth).x;
}

oneline_message_t[] get_oneline_messages(message_t[] messages)
{
    oneline_message_t[] oneline_messages;
    int                 i;

    for (i = 0; i < messages.length; ++i)
    {
        if (messages[i].dst == 0)
        {
            oneline_messages.push(
                oneline_message_t(messages[i].seq,
                                  messages[i].type,
                                  messages[i].src,
                                  messages[i].text));
        }
    }
    return oneline_messages;
}

/* FIXME:
 * 如果跨多列的消息长度大于这些列最大间距时，将出现消息越界问题。
 * 目前此问题只能通过增大图形总宽度来解决。
 */
real[] prelayout(message_t[] messages)
{
    real                last_object_offset = 0;
    real[]              objects_center_offset = {0,};
    int                 objects_count = get_objects_count(messages);
    real                leftwidth = 0;
    real                rightwidth = 0;
    int                 i;
    real                width;
    oneline_message_t[] oneline_messages = get_oneline_messages(messages);

    for (i = 0; i < oneline_messages.length; ++i)
    {
        if (oneline_messages[i].who == 1
            || oneline_messages[i].who == objects_count)
        {
            width = get_text_width(oneline_messages[i].text);

            if (oneline_messages[i].seq)
            {
                width += get_maxseqwidth();
            }
            /*if (messages[i].type > 1)
            {
                // FIXME: we should get the arrow size here.
                width += (2 * get_rowspacing());
            }*/

            if (oneline_messages[i].who == 1 && width > leftwidth)
            {
                leftwidth = width;
            }
            else if (oneline_messages[i].who== objects_count && width > rightwidth)
            {
                rightwidth = width;
            }
        }
    }
    leftwidth = max_real(leftwidth, get_text_width(objects[0].name));
    rightwidth = max_real(rightwidth, get_text_width(objects[objects_count-1].name));
    last_object_offset = (int)(leftwidth / 2);
    objects_center_offset.push(last_object_offset);

    for (i = 1; i < objects_count; ++i)
    {
        int             j;
        real            messagewidth;

        messagewidth = get_text_width(objects[i].name);
        for (j = 0; j < messages.length; ++j)
        {
            if ((messages[j].src == i && messages[j].dst == i+1) || (messages[j].src == i+1 && messages[j].dst == i))
            {
                width = get_text_width(messages[j].text);

                if (messages[j].seq)
                {
                    width += get_maxseqwidth();
                }
                /*if (messages[j].type > 1)
                {
                    // FIXME: we should get the arrow size here.
                    width += (2 * get_rowspacing());
                }*/

                if (width > messagewidth)
                {
                    messagewidth = width;
                }
            }
        }
        last_object_offset += messagewidth;
        objects_center_offset.push(last_object_offset);
    }

    objects_center_offset.push(last_object_offset+rightwidth);
    return objects_center_offset;
}

real[] layout(real maxwidth, message_t[] messages)
{
    real[]              offsets = prelayout(messages);
    int                 count = offsets.length;
    real                more = (int)((maxwidth - offsets[count-1]) / (count - 3));
    real[]              newoffsets;
    real                added = more;
    int                 i;

    if (more <= 0)
    {
        write('maxwidth = ', offsets[count-1]);
        return offsets;
    }

    newoffsets.push(offsets[1]);
    for (i = 2; i < count-1; ++i)
    {
        newoffsets.push(offsets[i] + added);
        added += more;
    }

    write('maxwidth = ', maxwidth);
    return newoffsets;
}

void textout(picture pic, real x, real y, string text, pen linecolor, pen textcolor)
{
    frame               frm;
    path                pth;

    pth = box(frm, text);
    //write('pth:', pth);
    //write('(x,y):', x, y);
    label(pic, text, (x,y), filltype=Fill(white), p=textcolor);
    draw((x,y), pth, p=linecolor);
}

int draw_oneline_message(picture pic, int seq, real[] offsets,
                          real yoffset, message_t message)
{
    real                src;
    string              seqstr = "";

    src = offsets[message.src-1];
    if (message.seq)
    {
        seqstr = format('(%d) ', seq);
        seq += 1;
    }

    if (message.type == 0)
    {
        textout(pic, src, yoffset, seqstr + message.text, message.linecolor, message.textcolor);
    }

    return seq;
}

void drawmsg(picture pic, real src, real dst, real yoffset,
        string text, arrowbar arrow=Arrow,
        pen linecolor, pen textcolor)
{
    real                center;

    draw(pic, (src,yoffset)--(dst,yoffset), p=linecolor+linewidth(0.4mm));
    draw(pic, (src,yoffset)--(dst,yoffset), arrow, p=linecolor+linewidth(0.2mm));
    dot((src,yoffset), p=linecolor);
    center = src + (dst - src) / 2;
    //textout(pic, center, yoffset, text);
    label(pic, text, (center, yoffset), filltype=Fill(white), p=textcolor);
}

int draw_message(picture pic, int seq, real[] offsets,
        real yoffset, message_t message)
{
    real                src;
    real                dst;
    string              seqstr = "";

    src = offsets[message.src-1];
    dst = offsets[message.dst-1];

    if (message.seq)
    {
        seqstr = format('(%d) ', seq);
        seq += 1;
    }

    if (message.type == 2)
    {
        drawmsg(pic, src, dst, yoffset, seqstr + message.text, message.linecolor, message.textcolor);
    }
    else if (message.type == 3)
    {
        drawmsg(pic, src, dst, yoffset, seqstr + message.text, Arrows, message.linecolor, message.textcolor);
    }

    return seq;
}

void drawobjects(picture fig, real[] offsets, real yoffset, object_t[] objects)
{
    int                 i;
    path                pth;

    for (i = 0; i < objects.length; ++i)
    {
        frame           frm;
        pth = box(frm, objects[i].name);
        //write('drawobjects', pth);
        add(fig, frm, (offsets[i], yoffset));
        draw(fig, (offsets[i],yoffset-get_rowspacing()/2)--(offsets[i],yoffset-800));
    }
}

real get_objects_yoffset(object_t[] objects, int src, int dst)
{
    int                 begin;
    int                 end;
    int                 i;
    real                tmp = 0;

    begin = min_int(src, dst)-1;
    end = max_int(src, dst)-1;
    //write('get_objects_yoffset:', begin, end);

    tmp = objects[begin].yoffset[1];
    tmp = min_real(tmp, objects[end].yoffset[0]);
    for (i = begin+1; i < end; ++i)
    {
        tmp = min_real(tmp, objects[i].yoffset[0]);
        tmp = min_real(tmp, objects[i].yoffset[1]);
        //write('get_objects_yoffset: tmp', tmp);
    }
    //write('get_objects_yoffset:', tmp);
    return tmp;
}

void update_objects_yoffset(object_t[] objects, int src, int dst, real yoffset)
{
    int                 begin;
    int                 end;
    int                 i;
    real                tmp;

    if (dst == 0)
    {
        dst = src;
    }

    begin = min_int(src, dst)-1;
    end = max_int(src, dst)-1;

    tmp = yoffset - get_rowspacing();
    //write("update_objects_yoffset", tmp);
    objects[begin].yoffset[1] = tmp;
    objects[end].yoffset[0] = tmp;

    for (i = begin+1; i < end; ++i)
    {
        objects[i].yoffset[0] = tmp;
        objects[i].yoffset[1] = tmp;
    }

    tmp = yoffset;
    for (i = 0; i < objects.length; ++i)
    {
        objects[i].yoffset[0] = min_real(tmp, objects[i].yoffset[0]);
        objects[i].yoffset[1] = min_real(tmp, objects[i].yoffset[1]);
    }

    /*for (i = 0; i < objects.length; ++i)
    {
        write("update_objects_yoffset:", i, objects[i].yoffset[0], objects[i].yoffset[1]);
    }*/
}

real get_min_yoffset(object_t[] objects)
{
    int                 i;
    real                yoffset = 0;

    for (i = 0; i < objects.length; ++i)
    {
        yoffset = min_real(yoffset, objects[i].yoffset[0]);
        yoffset = min_real(yoffset, objects[i].yoffset[1]);
    }

    return yoffset;
}

void drawout(real[] offsets, object_t[] objects,  message_t[] messages)
{
    int                 i;
    int                 seq = 1;
    real                src;
    real                dst;
    real                yoffset;
    picture             pic = currentpicture;

    drawobjects(pic, offsets, yoffset, objects);

    for (i = 0; i < messages.length; ++i)
    {
        src = offsets[messages[i].src-1];
        if (messages[i].dst == 0)
        {
            dst = 0;
            yoffset = min_real(objects[messages[i].src-1].yoffset[0],
                               objects[messages[i].src-1].yoffset[1]);
            //textout(pic, src, yoffset, messages[i].text);
            seq = draw_oneline_message(pic, seq, offsets, yoffset, messages[i]);
        }
        else
        {
            dst = offsets[messages[i].dst-1];
            yoffset = get_objects_yoffset(objects, messages[i].src, messages[i].dst);
            //write('drawout', yoffset);
            //seq = draw_message(pic, seq, src, dst, yoffset, messages[i].text);
            seq = draw_message(pic, seq, offsets, yoffset, messages[i]);
        }
        update_objects_yoffset(objects, messages[i].src, messages[i].dst, yoffset);
    }

    yoffset = get_min_yoffset(objects);
    clip(pic, (min(pic).x, yoffset)--(max(pic).x, yoffset)
         --(max(pic).x, max(pic).y)--(min(pic).x, max(pic).y)
         --cycle);
}

// Public API %% BEGIN
void showbox(string name)
{
    real[]              yoffset;

    yoffset.push(-get_rowspacing());
    yoffset.push(-get_rowspacing());
    objects.push(object_t(name, yoffset));
}

void event(int who, string text)
{
    messages.push(message_t(false, 0, who, 0, text, linecolor=red, textcolor=red));
}

void msg(int src, int dst, string text)
{
    messages.push(message_t(2, src, dst, text, textcolor=blue));
}

void rtp(int src, int dst, int type=3, string text="RTP")
{
    messages.push(message_t(false, type, src, dst, text, linecolor=green, textcolor=red));
}

void info(int src, int dst, string text)
{
    messages.push(message_t(false, 2, src, dst, text, textcolor=magenta));
}

void block(int src, int dst, int hight)
{
    int                 i;

    for (i = 0; i < hight; ++i)
    {
        messages.push(message_t(false, 0, src, dst, ''));
    }
}

void endmsg(int maxwidth = 600,
            object_t[] _objects = objects,
            message_t[] _messages = messages)
{
    real[]              offsets = layout(maxwidth, _messages);

    drawout(offsets, _objects, _messages);
}
// Public API %% END

/*
picture user()
{
    label("abc");
}

showbox('A');
showbox('AB');
showbox('ABC');
//showbox('ABCD');
//showbox('ABCDE');

event(1,'ABCDEFGHIJK');
event(2,'ABCDEFGHIJK');

msg(1,2,'abcdefghijklmnopq');
event(2,'ABCDEFGHIJK');
event(2,'ABCDEFGHIJK');
block(1,1,user);
msg(2,1,'abcdefghijklmnopq');
event(3,'ABCDEFGHIJK');
msg(2,3,'abcdefghijklmnopq');
msg(1,3,'abcdefghijklmnopq');

endmsg(500);
*/
