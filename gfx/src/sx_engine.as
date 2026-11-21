   var sxRoot;
   var sxLayers;
   var sxShapes;
   var sxMarkers;
   var sxPings;
   var sxPulse;
   var sxFlows;
   var sxPxPerUnit = 1;

   function SX_INIT()
   {
      if(this.sxRoot != undefined)
      {
         return undefined;
      }
      this.sxRoot = this.contentMC.createEmptyMovieClip("sxRoot",90000);
      this.sxLayers = new Object();
      this.sxShapes = new Object();
      this.sxMarkers = new Object();
      this.sxPings = new Object();
      this.sxPulse = new Object();
      this.sxFlows = new Object();
      var order = ["heat","zones","orders","preview","pings","trails","markers"];
      var i = 0;
      while(i < order.length)
      {
         var layer = this.sxRoot.createEmptyMovieClip(order[i],(i + 1) * 10);
         this.sxLayers[order[i]] = layer;
         this.sxShapes[order[i]] = new Object();
         i += 1;
      }
      this.sxRoot.onEnterFrame = mx.utils.Delegate.create(this,this.sxFrame);
   }

   function sxLayer(name)
   {
      this.SX_INIT();
      if(this.sxLayers[name] == undefined)
      {
         this.sxLayers[name] = this.sxRoot.createEmptyMovieClip(name,this.sxRoot.getNextHighestDepth());
         this.sxShapes[name] = new Object();
      }
      return this.sxLayers[name];
   }

   function SX_CLEAR_ALL()
   {
      this.SX_INIT();
      for(var name in this.sxLayers)
      {
         this.SX_LAYER_CLEAR(name);
      }
      for(var id in this.sxMarkers)
      {
         this.SX_MARKER_REMOVE(id);
      }
      for(var p in this.sxPings)
      {
         this.sxPings[p].mc.removeMovieClip();
      }
      this.sxPings = new Object();
   }

   function SX_LAYER_CLEAR(name)
   {
      var shapes = this.sxShapes[name];
      if(shapes == undefined)
      {
         return undefined;
      }
      for(var id in shapes)
      {
         shapes[id].removeMovieClip();
         delete this.sxPulse[name + ":" + id];
         delete this.sxFlows[name + ":" + id];
      }
      this.sxShapes[name] = new Object();
      this.sxLayers[name].clear();
   }

   function SX_LAYER_VISIBLE(name, visible)
   {
      this.sxLayer(name)._visible = visible;
   }

   function sxNewShape(layerName, id)
   {
      var layer = this.sxLayer(layerName);
      var shapes = this.sxShapes[layerName];
      if(shapes[id] != undefined)
      {
         shapes[id].removeMovieClip();
      }
      delete this.sxPulse[layerName + ":" + id];
      delete this.sxFlows[layerName + ":" + id];
      var mc = layer.createEmptyMovieClip("s_" + id,layer.getNextHighestDepth());
      shapes[id] = mc;
      return mc;
   }

   function SX_SHAPE_REMOVE(layerName, id)
   {
      var shapes = this.sxShapes[layerName];
      if(shapes != undefined && shapes[id] != undefined)
      {
         shapes[id].removeMovieClip();
         delete shapes[id];
      }
      delete this.sxPulse[layerName + ":" + id];
      delete this.sxFlows[layerName + ":" + id];
   }

   function sxCirclePath(mc, x, y, r)
   {
      var k = Math.tan(0.39269908169872414);
      var s = Math.sin(0.7853981633974483);
      mc.moveTo(x + r,y);
      mc.curveTo(x + r,y + k * r,x + s * r,y + s * r);
      mc.curveTo(x + k * r,y + r,x,y + r);
      mc.curveTo(x - k * r,y + r,x - s * r,y + s * r);
      mc.curveTo(x - r,y + k * r,x - r,y);
      mc.curveTo(x - r,y - k * r,x - s * r,y - s * r);
      mc.curveTo(x - k * r,y - r,x,y - r);
      mc.curveTo(x + k * r,y - r,x + s * r,y - s * r);
      mc.curveTo(x + r,y - k * r,x + r,y);
   }

   function sxPolyPath(mc, pts)
   {
      mc.moveTo(pts[0].x,pts[0].y);
      var i = 1;
      while(i < pts.length)
      {
         mc.lineTo(pts[i].x,pts[i].y);
         i += 1;
      }
      mc.lineTo(pts[0].x,pts[0].y);
   }

   function sxParsePoints(str)
   {
      var out = [];
      var parts = str.split("|");
      var i = 0;
      while(i < parts.length)
      {
         var xy = parts[i].split(",");
         if(xy.length >= 2)
         {
            out.push({x:Number(xy[0]),y:Number(xy[1])});
         }
         i += 1;
      }
      return out;
   }

   function sxCirclePoints(x, y, r, n)
   {
      var out = [];
      var i = 0;
      while(i < n)
      {
         var a = i / n * 6.283185307179586;
         out.push({x:x + Math.cos(a) * r,y:y + Math.sin(a) * r});
         i += 1;
      }
      return out;
   }

   function sxDashed(mc, pts, closed, dash, gap, offset)
   {
      var total = pts.length;
      var last = closed ? total : total - 1;
      var phase = offset % (dash + gap);
      if(phase < 0)
      {
         phase += dash + gap;
      }
      var i = 0;
      while(i < last)
      {
         var a = pts[i];
         var b = pts[(i + 1) % total];
         var dx = b.x - a.x;
         var dy = b.y - a.y;
         var len = Math.sqrt(dx * dx + dy * dy);
         if(len > 0)
         {
            var ux = dx / len;
            var uy = dy / len;
            var pos = - phase;
            while(pos < len)
            {
               var s = Math.max(pos,0);
               var e = Math.min(pos + dash,len);
               if(e > s)
               {
                  mc.moveTo(a.x + ux * s,a.y + uy * s);
                  mc.lineTo(a.x + ux * e,a.y + uy * e);
               }
               pos += dash + gap;
            }
            phase = (phase + len) % (dash + gap);
         }
         i += 1;
      }
   }

   function sxFill(mc, style, color, alpha, bx, by, bw, bh, cx, cy, r)
   {
      if(style == 1)
      {
         var m = {matrixType:"box",x:cx - r,y:cy - r,w:r * 2,h:r * 2,r:0};
         mc.beginGradientFill("radial",[color,color,color],[alpha * 0.32,alpha * 0.42,alpha * 0.9],[0,190,255],m);
      }
      else if(style != 2)
      {
         mc.beginFill(color,alpha);
      }
   }

   function sxHatch(mc, color, alpha, bx, by, bw, bh, pts, circle)
   {
      var hatch = mc.createEmptyMovieClip("hatch",10);
      var mask = mc.createEmptyMovieClip("mask",11);
      var step = Math.max(bw,bh) / 18;
      hatch.lineStyle(step * 0.22,color,alpha,false,"normal");
      var d = - bh;
      while(d < bw)
      {
         hatch.moveTo(bx + d,by + bh);
         hatch.lineTo(bx + d + bh,by);
         d += step;
      }
      mask.beginFill(0,100);
      if(circle != undefined)
      {
         this.sxCirclePath(mask,circle.x,circle.y,circle.r);
      }
      else
      {
         this.sxPolyPath(mask,pts);
      }
      mask.endFill();
      hatch.setMask(mask);
   }

   function sxBorder(mc, pts, color, border, dashed, closed, offset)
   {
      if(border <= 0)
      {
         return undefined;
      }
      mc.lineStyle(border,color,100,true,"none","round","round");
      if(dashed)
      {
         var size = 0;
         var i = 1;
         while(i < pts.length)
         {
            size += Math.abs(pts[i].x - pts[i - 1].x) + Math.abs(pts[i].y - pts[i - 1].y);
            i += 1;
         }
         var dash = Math.max(size / 60,4);
         this.sxDashed(mc,pts,closed,dash,dash * 0.7,offset);
      }
      else
      {
         mc.moveTo(pts[0].x,pts[0].y);
         var j = 1;
         while(j < pts.length)
         {
            mc.lineTo(pts[j].x,pts[j].y);
            j += 1;
         }
         if(closed)
         {
            mc.lineTo(pts[0].x,pts[0].y);
         }
      }
   }

   function SX_SHAPE_CIRCLE(layerName, id, x, y, r, color, alpha, style, border, flags)
   {
      var mc = this.sxNewShape(layerName,id);
      if(style == 2)
      {
         this.sxHatch(mc,color,alpha,x - r,y - r,r * 2,r * 2,undefined,{x:x,y:y,r:r});
      }
      else
      {
         this.sxFill(mc,style,color,alpha,x - r,y - r,r * 2,r * 2,x,y,r);
         this.sxCirclePath(mc,x,y,r);
         mc.endFill();
      }
      var outline = mc.createEmptyMovieClip("outline",20);
      if((flags & 2) != 0)
      {
         this.sxBorder(outline,this.sxCirclePoints(x,y,r,72),color,border,true,true,0);
      }
      else if(border > 0)
      {
         outline.lineStyle(border,color,100,true,"none");
         this.sxCirclePath(outline,x,y,r);
      }
      if((flags & 1) != 0)
      {
         this.sxPulse[layerName + ":" + id] = {mc:mc,base:100};
      }
   }

   function SX_SHAPE_POLY(layerName, id, points, color, alpha, style, border, flags)
   {
      var pts = this.sxParsePoints(points);
      if(pts.length < 3)
      {
         return undefined;
      }
      var mc = this.sxNewShape(layerName,id);
      var minX = pts[0].x;
      var maxX = pts[0].x;
      var minY = pts[0].y;
      var maxY = pts[0].y;
      var i = 1;
      while(i < pts.length)
      {
         minX = Math.min(minX,pts[i].x);
         maxX = Math.max(maxX,pts[i].x);
         minY = Math.min(minY,pts[i].y);
         maxY = Math.max(maxY,pts[i].y);
         i += 1;
      }
      if(style == 2)
      {
         this.sxHatch(mc,color,alpha,minX,minY,maxX - minX,maxY - minY,pts,undefined);
      }
      else
      {
         var cx = (minX + maxX) / 2;
         var cy = (minY + maxY) / 2;
         this.sxFill(mc,style,color,alpha,minX,minY,maxX - minX,maxY - minY,cx,cy,Math.max(maxX - minX,maxY - minY) / 2);
         this.sxPolyPath(mc,pts);
         mc.endFill();
      }
      var outline = mc.createEmptyMovieClip("outline",20);
      this.sxBorder(outline,pts,color,border,(flags & 2) != 0,true,0);
      if((flags & 1) != 0)
      {
         this.sxPulse[layerName + ":" + id] = {mc:mc,base:100};
      }
   }

   function sxDrawArrow(mc, x1, y1, x2, y2, color, width, offset, flow)
   {
      mc.clear();
      var dx = x2 - x1;
      var dy = y2 - y1;
      var len = Math.sqrt(dx * dx + dy * dy);
      if(len <= 0)
      {
         return undefined;
      }
      var ux = dx / len;
      var uy = dy / len;
      var head = Math.min(len * 0.25,Math.max(len * 0.12,30));
      var bx = x2 - ux * head;
      var by = y2 - uy * head;
      var pts = [{x:x1,y:y1},{x:bx,y:by}];
      mc.lineStyle(width,color,100,true,"none","none","round");
      if(flow)
      {
         this.sxDashed(mc,pts,false,head * 0.45,head * 0.3,offset);
      }
      else
      {
         mc.moveTo(x1,y1);
         mc.lineTo(bx,by);
      }
      mc.lineStyle(0,color,0);
      mc.beginFill(color,100);
      mc.moveTo(x2,y2);
      mc.lineTo(bx - uy * head * 0.55,by + ux * head * 0.55);
      mc.lineTo(bx + uy * head * 0.55,by - ux * head * 0.55);
      mc.lineTo(x2,y2);
      mc.endFill();
   }

   function SX_SHAPE_ARROW(layerName, id, x1, y1, x2, y2, color, width, flags)
   {
      var mc = this.sxNewShape(layerName,id);
      var flow = (flags & 4) != 0;
      this.sxDrawArrow(mc,x1,y1,x2,y2,color,width,0,flow);
      if(flow)
      {
         this.sxFlows[layerName + ":" + id] = {mc:mc,x1:x1,y1:y1,x2:x2,y2:y2,color:color,width:width};
      }
      if((flags & 1) != 0)
      {
         this.sxPulse[layerName + ":" + id] = {mc:mc,base:100};
      }
   }

   function sxDrawMarkerIcon(icon, color, flags)
   {
      icon.clear();
      var size = (flags & 4) != 0 ? 10 : 7.5;
      icon.lineStyle(2,0xFFFFFF,100,true,"none");
      icon.beginFill(color,100);
      this.sxCirclePath(icon,0,0,size);
      icon.endFill();
      icon.lineStyle(0,0,0);
      icon.beginFill(0xFFFFFF,100);
      icon.moveTo(0,- size - 7);
      icon.lineTo(-4.5,- size - 1);
      icon.lineTo(4.5,- size - 1);
      icon.lineTo(0,- size - 7);
      icon.endFill();
      if((flags & 4) != 0)
      {
         icon.beginFill(0xFFFFFF,100);
         this.sxCirclePath(icon,0,0,3);
         icon.endFill();
      }
   }

   function SX_MARKER(id, x, y, heading, color, flags, duration)
   {
      this.SX_INIT();
      var m = this.sxMarkers[id];
      if(m == undefined)
      {
         var layer = this.sxLayer("markers");
         var mc = layer.createEmptyMovieClip("m_" + id,layer.getNextHighestDepth());
         var trailLayer = this.sxLayer("trails");
         var trail = trailLayer.createEmptyMovieClip("t_" + id,trailLayer.getNextHighestDepth());
         var halo = mc.createEmptyMovieClip("halo",1);
         var icon = mc.createEmptyMovieClip("icon",2);
         m = {mc:mc,icon:icon,halo:halo,trail:trail,fx:x,fy:y,tx:x,ty:y,t0:getTimer(),dur:1,history:[],flags:-1,color:-1,flash:0};
         mc._x = x;
         mc._y = y;
         this.sxMarkers[id] = m;
      }
      m.fx = m.mc._x;
      m.fy = m.mc._y;
      m.tx = x;
      m.ty = y;
      m.t0 = getTimer();
      m.dur = Math.max(duration,0.05) * 1000;
      m.icon._rotation = heading;
      if((flags & 2) != 0)
      {
         m.flash = getTimer();
      }
      if(m.flags != flags || m.color != color)
      {
         m.flags = flags;
         m.color = color;
         this.sxDrawMarkerIcon(m.icon,color,flags);
      }
      var lastPoint = m.history[m.history.length - 1];
      if(lastPoint != undefined && Math.abs(lastPoint.x - x) + Math.abs(lastPoint.y - y) > 120)
      {
         m.history = [];
         m.fx = x;
         m.fy = y;
      }
      m.history.push({x:x,y:y});
      if(m.history.length > 14)
      {
         m.history.shift();
      }
      var trail = m.trail;
      trail.clear();
      var i = 1;
      while(i < m.history.length)
      {
         trail.lineStyle(3,color,i / m.history.length * 70,true,"none","round","round");
         trail.moveTo(m.history[i - 1].x,m.history[i - 1].y);
         trail.lineTo(m.history[i].x,m.history[i].y);
         i += 1;
      }
   }

   function SX_MARKER_REMOVE(id)
   {
      var m = this.sxMarkers[id];
      if(m != undefined)
      {
         m.mc.removeMovieClip();
         m.trail.removeMovieClip();
         delete this.sxMarkers[id];
      }
   }

   function SX_PING(id, x, y, color, life)
   {
      var layer = this.sxLayer("pings");
      if(this.sxPings[id] != undefined)
      {
         this.sxPings[id].mc.removeMovieClip();
      }
      var mc = layer.createEmptyMovieClip("p_" + id,layer.getNextHighestDepth());
      mc._x = x;
      mc._y = y;
      var dot = mc.createEmptyMovieClip("dot",2);
      dot.lineStyle(2,0xFFFFFF,100,true,"none");
      dot.beginFill(color,100);
      dot.moveTo(0,-8);
      dot.lineTo(8,0);
      dot.lineTo(0,8);
      dot.lineTo(-8,0);
      dot.lineTo(0,-8);
      dot.endFill();
      var ring = mc.createEmptyMovieClip("ring",1);
      ring.lineStyle(2,color,100,true,"none");
      this.sxCirclePath(ring,0,0,10);
      this.sxPings[id] = {mc:mc,ring:ring,t0:getTimer(),life:life * 1000};
   }

   function SX_HEAT(cell, data, color)
   {
      var layer = this.sxLayer("heat");
      this.SX_LAYER_CLEAR("heat");
      var mc = this.sxNewShape("heat","grid");
      var parts = String(data).split("|");
      var r = cell * 0.85;
      var i = 0;
      while(i < parts.length)
      {
         var v = parts[i].split(",");
         if(v.length >= 3)
         {
            var x = Number(v[0]);
            var y = Number(v[1]);
            var a = Math.min(Number(v[2]),1) * 70;
            var m = {matrixType:"box",x:x - r,y:y - r,w:r * 2,h:r * 2,r:0};
            mc.beginGradientFill("radial",[color,color],[a,0],[0,255],m);
            this.sxCirclePath(mc,x,y,r);
            mc.endFill();
         }
         i += 1;
      }
   }

   function sxFrame()
   {
      var now = getTimer();
      var p0 = {x:0,y:0};
      var p1 = {x:1000,y:0};
      this.sxRoot.localToGlobal(p0);
      this.sxRoot.localToGlobal(p1);
      var dx = p1.x - p0.x;
      var dy = p1.y - p0.y;
      var px = Math.sqrt(dx * dx + dy * dy) / 1000;
      if(px > 0)
      {
         this.sxPxPerUnit = px;
      }
      var inv = 100 / this.sxPxPerUnit;
      var wave = Math.sin(now / 260);

      for(var id in this.sxMarkers)
      {
         var m = this.sxMarkers[id];
         var t = Math.min((now - m.t0) / m.dur,1);
         var e = t * (2 - t);
         m.mc._x = m.fx + (m.tx - m.fx) * e;
         m.mc._y = m.fy + (m.ty - m.fy) * e;
         m.mc._xscale = inv;
         m.mc._yscale = inv;
         m.halo.clear();
         if((m.flags & 1) != 0)
         {
            m.halo.lineStyle(3,0xFF5A4F,60 + wave * 40,true,"none");
            this.sxCirclePath(m.halo,0,0,13 + wave * 2);
         }
         var since = now - m.flash;
         if(since < 450)
         {
            m.halo.lineStyle(3,0xFFC94D,100 - since / 4.5,true,"none");
            this.sxCirclePath(m.halo,0,0,9 + since / 18);
         }
      }

      for(var key in this.sxPulse)
      {
         var pulse = this.sxPulse[key];
         pulse.mc._alpha = pulse.base * (0.62 + 0.38 * wave);
      }

      for(var fk in this.sxFlows)
      {
         var f = this.sxFlows[fk];
         this.sxDrawArrow(f.mc,f.x1,f.y1,f.x2,f.y2,f.color,f.width,- now / 12,true);
      }

      for(var pid in this.sxPings)
      {
         var ping = this.sxPings[pid];
         var age = now - ping.t0;
         if(age >= ping.life)
         {
            ping.mc.removeMovieClip();
            delete this.sxPings[pid];
         }
         else
         {
            ping.mc._xscale = inv;
            ping.mc._yscale = inv;
            var cycle = (age % 1400) / 1400;
            ping.ring._xscale = 100 + cycle * 220;
            ping.ring._yscale = 100 + cycle * 220;
            ping.ring._alpha = 100 * (1 - cycle);
            ping.mc._alpha = age > ping.life - 15000 ? (ping.life - age) / 150 : 100;
         }
      }
   }
